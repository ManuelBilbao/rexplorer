defmodule Rexplorer.Schema.BalanceChange do
  @moduledoc """
  Records the absolute native-token balance of an address at a specific block.

  Only blocks where the balance actually changed produce a row. Each record
  stores the full balance (not a delta) so that charts can be rendered
  directly from a `SELECT ... ORDER BY block_number` query.

  The `source` field distinguishes between:
  - `"seed"` — baseline balance fetched via `eth_getBalance` at the block
    before the address was first seen by the indexer.
  - `"indexed"` — balance observed during normal block indexing.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "balance_changes" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :address_hash, :string
    field :block_number, :integer
    field :balance_wei, :decimal
    field :timestamp, :utc_datetime
    field :source, :string, default: "indexed"

    timestamps()
  end

  @doc "Changeset for creating a balance change record."
  def changeset(balance_change, attrs) do
    balance_change
    |> cast(attrs, [:chain_id, :address_hash, :block_number, :balance_wei, :timestamp, :source])
    |> validate_required([:chain_id, :address_hash, :block_number, :balance_wei, :timestamp])
    |> validate_inclusion(:source, ["seed", "indexed"])
    |> unique_constraint([:chain_id, :address_hash, :block_number])
    |> foreign_key_constraint(:chain_id)
  end
end
