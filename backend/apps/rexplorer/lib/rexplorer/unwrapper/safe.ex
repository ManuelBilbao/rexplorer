defmodule Rexplorer.Unwrapper.Safe do
  @moduledoc """
  Unwraps Safe multisig `execTransaction` calls.

  Detects transactions calling `execTransaction(address,uint256,bytes,uint8,...)`
  by its 4-byte selector `0x6a761202`. Extracts the inner call (to, value, data)
  and returns a `:multisig_execution` or `:delegate_call` operation with the
  Safe address as `from_address`.
  """

  @behaviour Rexplorer.Unwrapper

  alias Rexplorer.Decoder.ABI, as: ABIRegistry

  # execTransaction selector
  @exec_tx_selector <<0x6A, 0x76, 0x12, 0x02>>

  @impl true
  def matches?(%{input: <<selector::binary-size(4), _rest::binary>>}, _chain_id) do
    selector == @exec_tx_selector
  end

  def matches?(_, _), do: false

  @impl true
  def unwrap(transaction, _chain_id) do
    case ABIRegistry.decode(transaction.input) do
      {:ok, %{function: "execTransaction", params: params}} ->
        inner_to = params["to"]
        inner_value = params["value"] || 0
        inner_data = params["data"]
        operation = params["operation"] || 0

        op_type = if operation == 1, do: :delegate_call, else: :multisig_execution

        # Convert inner_data: ex_abi may return it as binary bytes
        inner_input = normalize_bytes(inner_data)

        [
          %{
            operation_type: op_type,
            operation_index: 0,
            from_address: transaction.to_address,
            to_address: normalize_address(inner_to),
            value: to_decimal(inner_value),
            input: inner_input
          }
        ]

      _ ->
        # Decode failed — fall back to empty (registry will use default)
        []
    end
  rescue
    _ -> []
  end

  defp normalize_address(addr) when is_binary(addr) and byte_size(addr) == 20 do
    "0x" <> Base.encode16(addr, case: :lower)
  end

  defp normalize_address(addr) when is_binary(addr), do: String.downcase(addr)
  defp normalize_address(nil), do: nil

  defp normalize_bytes(data) when is_binary(data), do: data
  defp normalize_bytes(_), do: nil

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(_), do: Decimal.new(0)
end
