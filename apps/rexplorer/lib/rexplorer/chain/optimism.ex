defmodule Rexplorer.Chain.Optimism do
  @moduledoc """
  Chain adapter for Optimism (chain ID: 10).

  OP Stack L2 with deposit transactions (type 0x7E), L1 block references,
  and canonical bridge via OptimismPortal.
  """

  use Rexplorer.Chain.EVM
  use Rexplorer.Chain.OPStack

  @impl true
  def chain_id, do: 10

  @impl true
  def chain_type, do: :optimistic_rollup

  @impl true
  def native_token, do: {"ETH", 18}

  @impl true
  def poll_interval_ms, do: 2_000

  @impl true
  def bridge_contracts do
    [
      "0xbeb5fc579115071764c7423a4f12edde41f106ed"
    ]
  end
end
