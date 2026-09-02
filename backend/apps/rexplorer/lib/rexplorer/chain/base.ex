defmodule Rexplorer.Chain.Base do
  @moduledoc """
  Chain adapter for Base (chain ID: 8453).

  OP Stack L2 built by Coinbase. Shares the same deposit transaction
  handling and L1 block references as Optimism.
  """

  use Rexplorer.Chain.EVM
  use Rexplorer.Chain.OPStack

  @impl true
  def chain_id, do: 8453

  @impl true
  def chain_type, do: :optimistic_rollup

  @impl true
  def native_token, do: {"ETH", 18}

  @impl true
  def poll_interval_ms, do: 2_000

  @impl true
  def bridge_contracts do
    [
      "0x49048044d57e1c92a77f79988d21fa8faf74e97e"
    ]
  end
end
