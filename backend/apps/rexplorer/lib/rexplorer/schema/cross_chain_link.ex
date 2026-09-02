defmodule Rexplorer.Schema.CrossChainLink do
  @moduledoc """
  Connects related transactions across different chains as part of a single
  user journey (e.g., L1 deposit → L2 relay, L2 withdrawal → L1 finalization).

  Links are identified by `message_hash` — the canonical bridge message
  identifier used by the chain's native bridge. The `destination_tx_hash`
  may be NULL when the destination side hasn't been indexed yet (e.g., a
  withdrawal that hasn't been proven/finalized).

  The `status` tracks the lifecycle of the cross-chain operation:
  - `initiated` — source transaction indexed, destination pending
  - `relayed` — destination transaction indexed (for deposits)
  - `proven` — withdrawal proof submitted (Optimistic rollups)
  - `finalized` — fully settled on both chains
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "cross_chain_links" do
    belongs_to :source_chain, Rexplorer.Schema.Chain,
      references: :chain_id,
      type: :integer,
      foreign_key: :source_chain_id

    belongs_to :destination_chain, Rexplorer.Schema.Chain,
      references: :chain_id,
      type: :integer,
      foreign_key: :destination_chain_id

    field :source_tx_hash, :string
    field :destination_tx_hash, :string

    field :link_type, Ecto.Enum, values: [:deposit, :withdrawal, :relay]
    field :message_hash, :string
    field :status, Ecto.Enum, values: [:initiated, :relayed, :proven, :finalized]

    timestamps()
  end

  @doc "Changeset for creating or updating a cross-chain link."
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:source_chain_id, :source_tx_hash, :destination_chain_id, :destination_tx_hash, :link_type, :message_hash, :status])
    |> validate_required([:source_chain_id, :source_tx_hash, :destination_chain_id, :link_type, :message_hash, :status])
    |> foreign_key_constraint(:source_chain_id)
    |> foreign_key_constraint(:destination_chain_id)
  end
end
