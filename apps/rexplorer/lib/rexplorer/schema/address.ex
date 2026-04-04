defmodule Rexplorer.Schema.Address do
  @moduledoc """
  Represents a unique address on a specific chain.

  Addresses are uniquely identified by `(chain_id, hash)`. The same 20-byte
  address on different chains produces separate records, each with independent
  metadata (labels, contract status, first seen timestamp).

  The `label` field can hold ENS names, known protocol names, or user-assigned
  labels. The `is_contract` flag indicates whether the address has deployed code.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :hash, :string
    field :is_contract, :boolean, default: false
    field :contract_code_hash, :string
    field :label, :string
    field :first_seen_at, :utc_datetime

    timestamps()
  end

  @doc "Changeset for creating or updating an address record."
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:chain_id, :hash, :is_contract, :contract_code_hash, :label, :first_seen_at])
    |> validate_required([:chain_id, :hash, :first_seen_at])
    |> unique_constraint([:chain_id, :hash])
    |> foreign_key_constraint(:chain_id)
  end
end
