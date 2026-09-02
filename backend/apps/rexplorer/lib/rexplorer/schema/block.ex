defmodule Rexplorer.Schema.Block do
  @moduledoc """
  Represents a block on a specific chain.

  Blocks are uniquely identified by `(chain_id, block_number)`. The `chain_extra`
  JSONB field stores chain-specific data (e.g., L2 batch index, blob gas used)
  whose structure is defined by each chain's adapter via `block_fields/0`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "blocks" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :block_number, :integer
    field :hash, :string
    field :parent_hash, :string
    field :timestamp, :utc_datetime
    field :gas_used, :integer
    field :gas_limit, :integer
    field :base_fee_per_gas, :integer
    field :chain_extra, :map, default: %{}
    field :transaction_count, :integer, virtual: true, default: 0

    has_many :transactions, Rexplorer.Schema.Transaction

    timestamps()
  end

  @doc "Changeset for creating or updating a block record."
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:chain_id, :block_number, :hash, :parent_hash, :timestamp, :gas_used, :gas_limit, :base_fee_per_gas, :chain_extra])
    |> validate_required([:chain_id, :block_number, :hash, :parent_hash, :timestamp, :gas_used, :gas_limit])
    |> unique_constraint([:chain_id, :block_number])
    |> unique_constraint([:chain_id, :hash])
    |> foreign_key_constraint(:chain_id)
  end
end
