defmodule Rexplorer.Schema.Chain do
  @moduledoc """
  Represents a supported blockchain network.

  Each chain is identified by its EIP-155 chain ID and stores network-specific
  configuration. The `chain_type` indicates the network's architecture (L1, optimistic
  rollup, ZK rollup, or sidechain), which determines what chain-specific fields
  and behaviors apply.

  Chains can be enabled or disabled at runtime without removing their data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type chain_type :: :l1 | :optimistic_rollup | :zk_rollup | :sidechain

  @primary_key {:chain_id, :integer, autogenerate: false}
  schema "chains" do
    field :name, :string
    field :chain_type, Ecto.Enum, values: [:l1, :optimistic_rollup, :zk_rollup, :sidechain]
    field :native_token_symbol, :string
    field :explorer_slug, :string
    field :rpc_config, :map, default: %{}
    field :enabled, :boolean, default: true

    has_many :blocks, Rexplorer.Schema.Block, foreign_key: :chain_id
    has_many :addresses, Rexplorer.Schema.Address, foreign_key: :chain_id

    timestamps()
  end

  @doc "Changeset for creating or updating a chain record."
  def changeset(chain, attrs) do
    chain
    |> cast(attrs, [:chain_id, :name, :chain_type, :native_token_symbol, :explorer_slug, :rpc_config, :enabled])
    |> validate_required([:chain_id, :name, :chain_type, :native_token_symbol, :explorer_slug])
    |> unique_constraint(:explorer_slug)
  end
end
