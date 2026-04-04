defmodule Rexplorer.Schema.Transaction do
  @moduledoc """
  Represents an on-chain transaction.

  Transactions are uniquely identified by `(chain_id, hash)`. Each transaction
  belongs to a block and may contain one or more operations (the user-intent
  abstraction). The `chain_extra` JSONB field stores chain-specific data
  (e.g., L1 origin hash for L2 deposit transactions).

  The `transaction_type` follows EIP-2718 encoding (0 = legacy, 1 = access list,
  2 = EIP-1559, 3 = blob, etc.).
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer
    belongs_to :block, Rexplorer.Schema.Block

    field :hash, :string
    field :from_address, :string
    field :to_address, :string
    field :value, :decimal, default: Decimal.new(0)
    field :input, :binary
    field :gas_price, :integer
    field :gas_used, :integer
    field :nonce, :integer
    field :transaction_type, :integer
    field :status, :boolean
    field :transaction_index, :integer
    field :chain_extra, :map, default: %{}

    has_many :operations, Rexplorer.Schema.Operation
    has_many :token_transfers, Rexplorer.Schema.TokenTransfer
    has_many :logs, Rexplorer.Schema.Log

    timestamps()
  end

  @doc "Changeset for creating or updating a transaction record."
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:chain_id, :hash, :block_id, :from_address, :to_address, :value, :input, :gas_price, :gas_used, :nonce, :transaction_type, :status, :transaction_index, :chain_extra])
    |> validate_required([:chain_id, :hash, :block_id, :from_address, :nonce, :transaction_index])
    |> unique_constraint([:chain_id, :hash])
    |> foreign_key_constraint(:chain_id)
    |> foreign_key_constraint(:block_id)
  end
end
