defmodule Rexplorer.Unwrapper.Multicall do
  @moduledoc """
  Unwraps multicall transactions into individual inner calls.

  Detects `multicall(bytes[])` (selector `0xac9650d8`) and
  `multicall(uint256,bytes[])` (selector `0x5ae401dc`, Uniswap V3 variant).
  Extracts each inner call from the bytes array and returns
  `:multicall_item` operations.
  """

  @behaviour Rexplorer.Unwrapper



  @multicall_selector <<0xAC, 0x96, 0x50, 0xD8>>
  @multicall_deadline_selector <<0x5A, 0xE4, 0x01, 0xDC>>

  @impl true
  def matches?(%{input: <<selector::binary-size(4), _rest::binary>>}, _chain_id) do
    selector == @multicall_selector or selector == @multicall_deadline_selector
  end

  def matches?(_, _), do: false

  @impl true
  def unwrap(transaction, _chain_id) do
    case extract_calls(transaction.input) do
      {:ok, calls} when calls != [] ->
        calls
        |> Enum.with_index()
        |> Enum.map(fn {inner_calldata, index} ->
          %{
            operation_type: :multicall_item,
            operation_index: index,
            from_address: transaction.from_address,
            to_address: transaction.to_address,
            value: transaction.value,
            input: normalize_bytes(inner_calldata)
          }
        end)

      _ ->
        # Empty or failed — fall back
        []
    end
  rescue
    _ -> []
  end

  defp extract_calls(<<@multicall_selector, params_data::binary>>) do
    decode_bytes_array(params_data)
  end

  defp extract_calls(<<@multicall_deadline_selector, params_data::binary>>) do
    # multicall(uint256 deadline, bytes[] data) — skip the first 32 bytes (deadline)
    decode_bytes_array_with_offset(params_data)
  end

  defp extract_calls(_), do: {:error, :unknown}

  defp decode_bytes_array(data) do
    # ABI-decode as bytes[]
    selector = %ABI.FunctionSelector{function: nil, types: [{:array, :bytes}]}

    case ABI.decode(selector, data) do
      [calls] when is_list(calls) -> {:ok, calls}
      _ -> {:error, :decode_failed}
    end
  rescue
    _ -> {:error, :decode_failed}
  end

  defp decode_bytes_array_with_offset(data) do
    # ABI-decode as (uint256, bytes[])
    selector = %ABI.FunctionSelector{function: nil, types: [{:uint, 256}, {:array, :bytes}]}

    case ABI.decode(selector, data) do
      [_deadline, calls] when is_list(calls) -> {:ok, calls}
      _ -> {:error, :decode_failed}
    end
  rescue
    _ -> {:error, :decode_failed}
  end

  defp normalize_bytes(data) when is_binary(data), do: data
  defp normalize_bytes(_), do: nil
end
