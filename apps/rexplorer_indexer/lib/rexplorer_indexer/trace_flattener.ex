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

  defp maybe_add(set, nil), do: set
  defp maybe_add(set, ""), do: set
  defp maybe_add(set, address) when is_binary(address), do: MapSet.put(set, String.downcase(address))
end
