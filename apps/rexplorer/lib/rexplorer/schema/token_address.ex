defmodule Rexplorer.Schema.TokenAddress do
  @moduledoc """
  Maps a canonical token to its contract address on a specific chain.

  The same token (e.g., USDC) can have different contract addresses on
  Ethereum, Optimism, Base, etc. This table enables cross-chain token
  resolution: given a contract address on any chain, we can resolve it
  to the canonical token for human-readable narration.

  Uniquely identified by `(chain_id, contract_address)`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "token_addresses" do
    belongs_to :token, Rexplorer.Schema.Token
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :contract_address, :string

    timestamps()
  end

  @doc "Changeset for creating or updating a token address mapping."
  def changeset(token_address, attrs) do
    token_address
    |> cast(attrs, [:token_id, :chain_id, :contract_address])
    |> validate_required([:token_id, :chain_id, :contract_address])
    |> unique_constraint([:chain_id, :contract_address])
    |> foreign_key_constraint(:token_id)
    |> foreign_key_constraint(:chain_id)
  end
end
