defmodule Rexplorer.Decoder.EventDecoder do
  @moduledoc """
  Decodes event logs into structured data using the ABI event registry.

  Takes a raw log (with topic0-3 and data) and returns a decoded map
  with event name, decoded parameters, and a human-readable summary.
  """

  alias Rexplorer.Decoder.ABI, as: ABIRegistry

  @doc """
  Decodes a log into structured event data.

  Returns `%{event_name: string, params: map, summary: string}` or `nil` for unknown events.
  """
  def decode_log(log, token_cache \\ %{}) do
    topic0 = log.topic0

    case ABIRegistry.lookup_event(topic0) do
      nil -> nil
      event_def -> decode_with_definition(log, event_def, token_cache)
    end
  end

  defp decode_with_definition(log, event_def, token_cache) do
    topics = [log.topic1, log.topic2, log.topic3] |> Enum.reject(&is_nil/1)
    data = log.data

    # Split types into indexed (from topics) and non-indexed (from data)
    {indexed_types, data_types, indexed_names, data_names} =
      split_by_indexed(event_def.types, event_def.param_names, event_def.indexed)

    # Decode indexed params from topics
    indexed_params = decode_indexed(topics, indexed_types, indexed_names)

    # Decode non-indexed params from data
    data_params = decode_data(data, data_types, data_names)

    # Merge in original order
    params = merge_params(event_def.param_names, indexed_params, data_params)

    summary = format_summary(event_def.event_name, params, log.contract_address, token_cache)

    %{
      event_name: event_def.event_name,
      params: stringify_params(params),
      summary: summary
    }
  rescue
    _ -> nil
  end

  defp split_by_indexed(types, names, indexed) do
    zipped = Enum.zip([types, names, indexed])

    indexed_items = Enum.filter(zipped, fn {_t, _n, i} -> i end)
    data_items = Enum.filter(zipped, fn {_t, _n, i} -> !i end)

    {
      Enum.map(indexed_items, &elem(&1, 0)),
      Enum.map(data_items, &elem(&1, 0)),
      Enum.map(indexed_items, &elem(&1, 1)),
      Enum.map(data_items, &elem(&1, 1))
    }
  end

  defp decode_indexed(topics, types, names) do
    Enum.zip([topics, types, names])
    |> Enum.map(fn {topic_hex, type, name} ->
      value = decode_topic(topic_hex, type)
      {name, value}
    end)
    |> Map.new()
  end

  defp decode_topic(nil, _type), do: nil

  defp decode_topic("0x" <> hex, :address) do
    # Address is 32 bytes zero-padded, take last 40 chars
    "0x" <> String.slice(hex, -40, 40)
  end

  defp decode_topic("0x" <> hex, {:int, _}), do: String.to_integer(hex, 16)
  defp decode_topic("0x" <> hex, {:uint, _}), do: String.to_integer(hex, 16)
  defp decode_topic(hex, _type), do: hex

  defp decode_data(nil, _types, _names), do: %{}
  defp decode_data(data, [], _names), do: if(data == <<>>, do: %{}, else: %{})

  defp decode_data(data, types, names) when is_binary(data) and byte_size(data) > 0 do
    selector = %ABI.FunctionSelector{function: nil, types: types}

    case ABI.decode(selector, data) do
      values when is_list(values) ->
        Enum.zip(names, values)
        |> Enum.map(fn {name, value} -> {name, format_decoded_value(value)} end)
        |> Map.new()

      _ ->
        %{}
    end
  rescue
    _ -> %{}
  end

  defp decode_data(_, _, _), do: %{}

  defp merge_params(all_names, indexed, data) do
    Map.new(all_names, fn name ->
      {name, Map.get(indexed, name) || Map.get(data, name)}
    end)
  end

  defp format_decoded_value(value) when is_binary(value) and byte_size(value) == 20 do
    "0x" <> Base.encode16(value, case: :lower)
  end

  defp format_decoded_value(value), do: value

  defp stringify_params(params) do
    Map.new(params, fn {k, v} -> {k, to_string_value(v)} end)
  end

  defp to_string_value(v) when is_integer(v), do: Integer.to_string(v)
  defp to_string_value(v) when is_binary(v), do: v
  defp to_string_value(v) when is_boolean(v), do: to_string(v)
  defp to_string_value(nil), do: nil
  defp to_string_value(v), do: inspect(v)

  # Summary formatting per event type

  defp format_summary("Transfer", params, contract_addr, token_cache) do
    token = resolve_token(contract_addr, token_cache)
    amount = format_amount(params["value"], token)
    from = truncate(params["from"])
    to = truncate(params["to"])
    "Transfer #{amount} #{token.symbol} from #{from} to #{to}"
  end

  defp format_summary("Approval", params, contract_addr, token_cache) do
    token = resolve_token(contract_addr, token_cache)
    amount = format_amount(params["value"], token)
    owner = truncate(params["owner"])
    spender = truncate(params["spender"])
    "Approval: #{owner} approved #{spender} for #{amount} #{token.symbol}"
  end

  defp format_summary("Swap", params, contract_addr, _token_cache) do
    pool = truncate(contract_addr)

    cond do
      # Uniswap V2 style
      params["amount0In"] ->
        "Swap on pool #{pool}"

      # Uniswap V3 style
      params["amount0"] ->
        "Swap on pool #{pool}"

      true ->
        "Swap on #{pool}"
    end
  end

  defp format_summary("Supply", params, _contract_addr, token_cache) do
    token = resolve_token(params["reserve"], token_cache)
    amount = format_amount(params["amount"], token)
    "Supply #{amount} #{token.symbol} to Aave"
  end

  defp format_summary("Withdraw", params, _contract_addr, token_cache) do
    token = resolve_token(params["reserve"], token_cache)
    amount = format_amount(params["amount"], token)
    "Withdraw #{amount} #{token.symbol} from Aave"
  end

  defp format_summary("Borrow", params, _contract_addr, token_cache) do
    token = resolve_token(params["reserve"], token_cache)
    amount = format_amount(params["amount"], token)
    "Borrow #{amount} #{token.symbol} from Aave"
  end

  defp format_summary("Repay", params, _contract_addr, token_cache) do
    token = resolve_token(params["reserve"], token_cache)
    amount = format_amount(params["amount"], token)
    "Repay #{amount} #{token.symbol} to Aave"
  end

  defp format_summary("Deposit", params, _contract_addr, _token_cache) do
    amount = format_raw(params["wad"], 18)
    "WETH Deposit #{amount} ETH"
  end

  defp format_summary("Withdrawal", params, _contract_addr, _token_cache) do
    amount = format_raw(params["wad"], 18)
    "WETH Withdrawal #{amount} ETH"
  end

  defp format_summary(event_name, _params, contract_addr, _token_cache) do
    "#{event_name} on #{truncate(contract_addr)}"
  end

  # Helpers

  defp resolve_token(nil, _cache), do: %{symbol: "???", decimals: 18}

  defp resolve_token(addr, cache) when is_binary(addr) do
    Map.get(cache, String.downcase(addr), %{symbol: truncate(addr), decimals: 18})
  end

  defp resolve_token(_, _), do: %{symbol: "???", decimals: 18}

  defp format_amount(nil, _token), do: "?"
  defp format_amount(val, token) when is_integer(val), do: format_raw(val, token.decimals)

  defp format_amount(val, token) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> format_raw(n, token.decimals)
      _ -> val
    end
  end

  defp format_amount(val, _), do: to_string(val)

  defp format_raw(nil, _), do: "?"

  defp format_raw(amount, decimals) when is_integer(amount) and is_integer(decimals) do
    value = amount / :math.pow(10, decimals)

    if value == trunc(value) do
      trunc(value) |> Integer.to_string()
    else
      :erlang.float_to_binary(value, decimals: min(6, decimals))
      |> String.trim_trailing("0")
      |> String.trim_trailing(".")
    end
  end

  defp format_raw(v, _), do: to_string(v)

  defp truncate(nil), do: "???"

  defp truncate(addr) when is_binary(addr) and byte_size(addr) > 12 do
    String.slice(addr, 0, 6) <> "..." <> String.slice(addr, -4, 4)
  end

  defp truncate(addr), do: to_string(addr)
end
