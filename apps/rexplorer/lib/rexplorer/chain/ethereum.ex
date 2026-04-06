defmodule Rexplorer.Chain.Ethereum do
  @moduledoc """
  Chain adapter for Ethereum mainnet (chain ID: 1).

  This is the reference implementation of the `Rexplorer.Chain.Adapter` behaviour.
  Ethereum mainnet has no chain-specific block or transaction extensions and
  no native bridge contracts. Operation extraction produces a single `call`
  operation per transaction.
  """

  @behaviour Rexplorer.Chain.Adapter

  @impl true
  def chain_id, do: 1

  @impl true
  def chain_type, do: :l1

  @impl true
  def native_token, do: {"ETH", 18}

  @impl true
  def block_fields, do: []

  @impl true
  def transaction_fields, do: []

  @impl true
  def extract_operations(transaction) do
    Rexplorer.Unwrapper.Registry.unwrap(transaction, chain_id())
  end

  @impl true
  def bridge_contracts, do: []

  @impl true
  def poll_interval_ms, do: 12_000

  # ERC-20 Transfer(address,address,uint256) event signature
  @erc20_transfer_topic "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  @native_token_address "0x0000000000000000000000000000000000000000"

  @impl true
  def extract_token_transfers(transaction) do
    native_transfers = extract_native_transfer(transaction)
    erc20_transfers = extract_erc20_transfers(transaction)
    native_transfers ++ erc20_transfers
  end

  defp extract_native_transfer(%{value: value, from_address: from, to_address: to})
       when not is_nil(to) do
    if Decimal.gt?(value, Decimal.new(0)) do
      [
        %{
          from_address: from,
          to_address: to,
          token_contract_address: @native_token_address,
          amount: value,
          token_type: :native,
          token_id: nil
        }
      ]
    else
      []
    end
  end

  defp extract_native_transfer(_), do: []

  defp extract_erc20_transfers(%{logs: logs}) when is_list(logs) do
    logs
    |> Enum.filter(&erc20_transfer?/1)
    |> Enum.map(&decode_erc20_transfer/1)
  end

  defp extract_erc20_transfers(_), do: []

  defp erc20_transfer?(%{topic0: topic0}) when topic0 == @erc20_transfer_topic, do: true
  defp erc20_transfer?(_), do: false

  defp decode_erc20_transfer(log) do
    %{
      from_address: decode_address_topic(log.topic1),
      to_address: decode_address_topic(log.topic2),
      token_contract_address: log.contract_address,
      amount: decode_uint256(log.data),
      token_type: :erc20,
      token_id: nil
    }
  end

  defp decode_address_topic(nil), do: nil

  defp decode_address_topic("0x" <> hex) do
    # Address is right-padded to 32 bytes in topic, take last 40 chars
    "0x" <> String.slice(hex, -40, 40)
  end

  defp decode_uint256(nil), do: Decimal.new(0)
  defp decode_uint256("0x"), do: Decimal.new(0)

  defp decode_uint256("0x" <> hex) when byte_size(hex) > 0 do
    hex
    |> String.to_integer(16)
    |> Decimal.new()
  end

  defp decode_uint256(_), do: Decimal.new(0)
end
