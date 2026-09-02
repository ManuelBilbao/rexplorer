defmodule Rexplorer.Schema.Token do
  @moduledoc """
  Represents a canonical token (e.g., USDC, WETH).

  A token is a logical entity that may exist on multiple chains at different
  contract addresses. The `token_addresses` association maps this token to
  its per-chain deployments. This design allows the decoder pipeline to
  resolve "0xA0b8..." into "USDC" regardless of which chain the transfer
  occurred on.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :name, :string
    field :symbol, :string
    field :decimals, :integer
    field :logo_url, :string

    has_many :token_addresses, Rexplorer.Schema.TokenAddress

    timestamps()
  end

  @doc "Changeset for creating or updating a token record."
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:name, :symbol, :decimals, :logo_url])
    |> validate_required([:name, :symbol, :decimals])
    |> validate_number(:decimals, greater_than_or_equal_to: 0)
  end
end
