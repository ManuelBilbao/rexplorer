defmodule Rexplorer.Chain.Ethereum do
  @moduledoc """
  Chain adapter for Ethereum mainnet (chain ID: 1).

  Uses the shared EVM base module. Ethereum has no chain-specific block or
  transaction extensions and no native bridge contracts.
  """

  use Rexplorer.Chain.EVM

  @impl true
  def chain_id, do: 1

  @impl true
  def chain_type, do: :l1

  @impl true
  def native_token, do: {"ETH", 18}

  @impl true
  def poll_interval_ms, do: 12_000
end
