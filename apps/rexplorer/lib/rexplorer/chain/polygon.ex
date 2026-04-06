defmodule Rexplorer.Chain.Polygon do
  @moduledoc """
  Chain adapter for Polygon (chain ID: 137).

  EVM-compatible sidechain with 2-second block times and POL as
  the native token.
  """

  use Rexplorer.Chain.EVM

  @impl true
  def chain_id, do: 137

  @impl true
  def chain_type, do: :sidechain

  @impl true
  def native_token, do: {"POL", 18}

  @impl true
  def poll_interval_ms, do: 2_000
end
