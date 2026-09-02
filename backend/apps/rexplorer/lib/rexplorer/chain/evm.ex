defmodule Rexplorer.Chain.EVM do
  @moduledoc """
  Shared base module for EVM-compatible chain adapters.

  Provides default implementations for all `Rexplorer.Chain.Adapter` callbacks
  that are common across EVM chains: operation extraction (unwrapper delegation),
  token transfer extraction (native + ERC-20), and empty defaults for chain-specific
  fields and bridge contracts.

  ## Usage

      defmodule Rexplorer.Chain.MyChain do
        use Rexplorer.Chain.EVM

        @impl true
        def chain_id, do: 42
        @impl true
        def chain_type, do: :sidechain
        @impl true
        def native_token, do: {"TOKEN", 18}
        @impl true
        def poll_interval_ms, do: 5_000
      end

  Chain adapters MUST define: `chain_id/0`, `chain_type/0`, `native_token/0`,
  `poll_interval_ms/0`. All other callbacks have working defaults that can be
  overridden.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour Rexplorer.Chain.Adapter

      @impl true
      def extract_operations(transaction) do
        Rexplorer.Unwrapper.Registry.unwrap(transaction, chain_id())
      end

      @impl true
      def extract_token_transfers(transaction) do
        Rexplorer.Chain.EVM.do_extract_token_transfers(transaction)
      end

      @impl true
      def block_fields, do: []

      @impl true
      def transaction_fields, do: []

      @impl true
      def bridge_contracts, do: []

      @impl true
      def supports_traces?, do: false

      defoverridable extract_operations: 1,
                     extract_token_transfers: 1,
                     block_fields: 0,
                     transaction_fields: 0,
                     bridge_contracts: 0,
                     supports_traces?: 0
    end
  end

  # ERC-20 Transfer(address,address,uint256) event signature
  @erc20_transfer_topic "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  @native_token_address "0x0000000000000000000000000000000000000000"

  @doc false
  def do_extract_token_transfers(transaction) do
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

  defp erc20_transfer?(%{topic0: topic0, topic1: t1, topic2: t2})
       when topic0 == @erc20_transfer_topic and not is_nil(t1) and not is_nil(t2),
       do: true

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

  @doc false
  def decode_address_topic(nil), do: nil

  def decode_address_topic("0x" <> hex) do
    "0x" <> String.slice(hex, -40, 40)
  end

  @doc false
  def decode_uint256(nil), do: Decimal.new(0)
  def decode_uint256("0x"), do: Decimal.new(0)

  def decode_uint256("0x" <> hex) when byte_size(hex) > 0 do
    hex
    |> String.to_integer(16)
    |> Decimal.new()
  end

  def decode_uint256(_), do: Decimal.new(0)
end
