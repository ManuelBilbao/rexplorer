defmodule Rexplorer.Chain.BNB do
  @moduledoc """
  Chain adapter for BNB Smart Chain (chain ID: 56).

  EVM-compatible sidechain with 3-second block times and BNB as
  the native token.
  """

  use Rexplorer.Chain.EVM

  @impl true
  def chain_id, do: 56

  @impl true
  def chain_type, do: :sidechain

  @impl true
  def native_token, do: {"BNB", 18}

  @impl true
  def poll_interval_ms, do: 3_000
end
