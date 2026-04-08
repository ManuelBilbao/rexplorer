defmodule RexplorerIndexer.TraceFlattener do
  @moduledoc """
  Extracts all unique addresses from `callTracer` trace output.

  The `debug_traceBlockByNumber` RPC call with `callTracer` returns a nested
  call tree per transaction. This module recursively walks those trees and
  collects every `from` and `to` address, covering internal calls, CREATEs,
  and SELFDESTRUCTs that are invisible at the transaction level.

  ## Workflow

  ```mermaid
  sequenceDiagram
      participant W as Indexer Worker
      participant RPC as RPC Node
      participant TF as TraceFlattener

      W->>RPC: debug_traceBlockByNumber(N, {callTracer})
      RPC-->>W: [%{"txHash" => ..., "result" => call_frame}, ...]
      W->>TF: flatten_traces(traces)
      TF-->>TF: Walk each call_frame recursively
      TF-->>TF: Collect from/to at each level
      TF-->>W: MapSet of all unique addresses
  ```
  """

  @doc """
  Extracts all unique addresses from a list of block trace results.

  Takes the output of `debug_traceBlockByNumber` — a list of
  `%{"txHash" => ..., "result" => call_frame}` maps — and returns a
  `MapSet` of all lowercase addresses found in the call trees.

  ## Example

      iex> traces = [%{"txHash" => "0x...", "result" => %{"from" => "0xA", "to" => "0xB", "calls" => [...]}}]
      iex> TraceFlattener.flatten_traces(traces)
      #MapSet<["0xa", "0xb", ...]>
  """
  @spec flatten_traces(list(map())) :: MapSet.t(String.t())
  def flatten_traces(traces) when is_list(traces) do
    traces
    |> Enum.reduce(MapSet.new(), fn trace, acc ->
      case trace do
        %{"result" => frame} when is_map(frame) ->
          flatten_frame(frame, acc)

        %{"result" => frames} when is_list(frames) ->
          Enum.reduce(frames, acc, &flatten_frame/2)

        _ ->
          acc
      end
    end)
  end

  def flatten_traces(_), do: MapSet.new()

  @doc """
  Extracts all unique addresses from a single call frame.

  Recursively walks the nested `"calls"` array, collecting `from` and `to`
  at every level.
  """
  @spec flatten_frame(map(), MapSet.t(String.t())) :: MapSet.t(String.t())
  def flatten_frame(frame, acc \\ MapSet.new())

  def flatten_frame(%{} = frame, acc) do
    acc =
      acc
      |> maybe_add(frame["from"])
      |> maybe_add(frame["to"])

    case frame["calls"] do
      calls when is_list(calls) ->
        Enum.reduce(calls, acc, &flatten_frame/2)

      _ ->
        acc
    end
  end

  def flatten_frame(_, acc), do: acc

  @doc """
  Converts callTracer output into a flat list of value-transferring internal transaction entries.

  Returns a list of maps ready for DB insertion. Only includes entries where:
  - `value > 0` (ETH was transferred), OR
  - `type` is CREATE, CREATE2, or SELFDESTRUCT

  Each entry includes a `trace_index` (sequential per block) and `trace_address`
  (integer array path in the call tree).

  ```mermaid
  sequenceDiagram
      participant W as Worker
      participant TF as TraceFlattener
      W->>TF: flatten_to_entries(traces)
      TF-->>TF: Walk each tx trace recursively
      TF-->>TF: Filter: value > 0 or CREATE/SELFDESTRUCT
      TF-->>TF: Assign trace_address path + trace_index
      TF-->>W: List of entry maps
  ```
  """
  @spec flatten_to_entries(list(map())) :: list(map())
  def flatten_to_entries(traces) when is_list(traces) do
    {entries, _counter} =
      traces
      |> Enum.with_index()
      |> Enum.reduce({[], 0}, fn {trace, tx_pos}, {acc, counter} ->
        tx_hash = trace["txHash"]

        frames =
          case trace do
            %{"result" => frame} when is_map(frame) -> [frame]
            %{"result" => frames} when is_list(frames) -> frames
            _ -> []
          end

        # Use transactionPosition if available, otherwise use array position
        tx_index = trace["transactionPosition"] || tx_pos

        {new_entries, new_counter} =
          Enum.reduce(frames, {[], counter}, fn frame, {frame_acc, idx} ->
            walk_frame_for_entries(frame, tx_hash, tx_index, [], frame_acc, idx)
          end)

        {acc ++ Enum.reverse(new_entries), new_counter}
      end)

    entries
  end

  def flatten_to_entries(_), do: []

  # Recursively walk a call frame, collecting value-transferring entries
  defp walk_frame_for_entries(frame, tx_hash, tx_index, path, acc, counter) when is_map(frame) do
    call_type = normalize_call_type(frame["type"])
    value = parse_hex_value(frame["value"])
    is_value_transfer = value > 0
    is_create = call_type in ["create", "create2"]
    is_selfdestruct = call_type == "selfdestruct"

    {acc, counter} =
      if is_value_transfer or is_create or is_selfdestruct do
        entry = %{
          transaction_hash: tx_hash,
          transaction_index: tx_index,
          trace_index: counter,
          from_address: downcase(frame["from"]),
          to_address: downcase(frame["to"]),
          value: Decimal.new(value),
          call_type: call_type,
          trace_address: path,
          input_prefix: extract_input_prefix(frame["input"]),
          error: frame["error"]
        }

        {[entry | acc], counter + 1}
      else
        {acc, counter}
      end

    # Recurse into subcalls
    case frame["calls"] do
      calls when is_list(calls) ->
        calls
        |> Enum.with_index()
        |> Enum.reduce({acc, counter}, fn {subcall, idx}, {sub_acc, sub_counter} ->
          walk_frame_for_entries(subcall, tx_hash, tx_index, path ++ [idx], sub_acc, sub_counter)
        end)

      _ ->
        {acc, counter}
    end
  end

  defp walk_frame_for_entries(_, _tx_hash, _tx_index, _path, acc, counter), do: {acc, counter}

  defp normalize_call_type(nil), do: "call"
  defp normalize_call_type(type) when is_binary(type), do: String.downcase(type)

  defp parse_hex_value(nil), do: 0
  defp parse_hex_value("0x0"), do: 0
  defp parse_hex_value("0x" <> hex) when byte_size(hex) > 0, do: String.to_integer(hex, 16)
  defp parse_hex_value(_), do: 0

  defp extract_input_prefix(nil), do: nil
  defp extract_input_prefix("0x"), do: nil
  defp extract_input_prefix("0x" <> hex) when byte_size(hex) >= 8 do
    hex |> String.slice(0, 8) |> Base.decode16!(case: :mixed)
  end
  defp extract_input_prefix(_), do: nil

  defp downcase(nil), do: nil
  defp downcase(s) when is_binary(s), do: String.downcase(s)

  defp maybe_add(set, nil), do: set
  defp maybe_add(set, ""), do: set
  defp maybe_add(set, address) when is_binary(address), do: MapSet.put(set, String.downcase(address))
end
