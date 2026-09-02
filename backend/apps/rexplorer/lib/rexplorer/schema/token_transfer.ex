defmodule Rexplorer.Schema.TokenTransfer do
  @moduledoc """
  Represents a token transfer event within a transaction.

  Covers all transfer types: native currency (ETH/BNB/MATIC), ERC-20, ERC-721,
  and ERC-1155. Native transfers are extracted from the transaction's `value`
  field; token transfers are extracted from `Transfer` event logs.

  The `amount` is stored as a raw numeric value (no decimal adjustment).
  To get the human-readable amount, divide by `10^decimals` using the
  associated token's metadata.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "token_transfers" do
    belongs_to :transaction, Rexplorer.Schema.Transaction
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :from_address, :string
    field :to_address, :string
    field :token_contract_address, :string
    field :amount, :decimal
    field :token_type, Ecto.Enum, values: [:native, :erc20, :erc721, :erc1155]
    field :token_id, :string
    field :frame_index, :integer

    timestamps()
  end

  @doc "Changeset for creating or updating a token transfer record."
  def changeset(token_transfer, attrs) do
    token_transfer
    |> cast(attrs, [:transaction_id, :chain_id, :from_address, :to_address, :token_contract_address, :amount, :token_type, :token_id, :frame_index])
    |> validate_required([:transaction_id, :chain_id, :from_address, :to_address, :token_contract_address, :amount, :token_type])
    |> foreign_key_constraint(:transaction_id)
    |> foreign_key_constraint(:chain_id)
  end
end
