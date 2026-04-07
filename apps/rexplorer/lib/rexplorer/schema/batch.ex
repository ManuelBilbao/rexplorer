defmodule Rexplorer.Schema.Batch do
  @moduledoc """
  Represents an L2 batch — a group of consecutive blocks that are committed
  and verified together on L1.

  Used by ZK rollup chains (Ethrex) to track the batch lifecycle:
  - `sealed` — batch created locally by the sequencer
  - `committed` — batch data committed to L1 (`commit_tx_hash` set)
  - `verified` — ZK proof verified on L1 (`verify_tx_hash` set)

  Each batch maps to a range of L2 blocks (`first_block` → `last_block`).
  Blocks also store `batch_number` in their `chain_extra` JSONB for O(1) lookup.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "batches" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :batch_number, :integer
    field :first_block, :integer
    field :last_block, :integer
    field :status, Ecto.Enum, values: [:sealed, :committed, :verified]
    field :commit_tx_hash, :string
    field :verify_tx_hash, :string

    timestamps()
  end

  @doc "Changeset for creating or updating a batch record."
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [:chain_id, :batch_number, :first_block, :last_block, :status, :commit_tx_hash, :verify_tx_hash])
    |> validate_required([:chain_id, :batch_number, :first_block, :last_block, :status])
    |> unique_constraint([:chain_id, :batch_number])
    |> foreign_key_constraint(:chain_id)
  end
end
