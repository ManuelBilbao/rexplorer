defmodule Rexplorer.Addresses do
  @moduledoc """
  Query module for address records.

  Provides functions to retrieve address metadata and aggregated overviews
  with recent transactions and token transfers.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Address, Schema.Transaction, Schema.TokenTransfer}

  @doc "Returns an address by chain_id and hash."
  def get_address(chain_id, hash) do
    hash = String.downcase(hash)

    case Repo.get_by(Address, chain_id: chain_id, hash: hash) do
      nil -> {:error, :not_found}
      address -> {:ok, address}
    end
  end

  @doc """
  Returns an address with recent transactions and token transfers.
  Used by the BFF for the address overview page.
  """
  def get_address_overview(chain_id, hash, opts \\ []) do
    hash = String.downcase(hash)
    limit = opts[:limit] || 25

    case Repo.get_by(Address, chain_id: chain_id, hash: hash) do
      nil ->
        {:error, :not_found}

      address ->
        recent_txs =
          Transaction
          |> where([t], t.chain_id == ^chain_id)
          |> where([t], t.from_address == ^hash or t.to_address == ^hash)
          |> order_by([t], desc: t.id)
          |> limit(^limit)
          |> preload(:block)
          |> Repo.all()

        recent_transfers =
          TokenTransfer
          |> where([tt], tt.chain_id == ^chain_id)
          |> where([tt], tt.from_address == ^hash or tt.to_address == ^hash)
          |> order_by([tt], desc: tt.id)
          |> limit(^limit)
          |> Repo.all()

        {:ok, address, recent_txs, recent_transfers}
    end
  end

  @doc """
  Returns paginated token transfers for an address.

  Options:
  - `:before` — id cursor
  - `:limit` — max results (default 25, max 100)
  """
  def list_token_transfers(chain_id, hash, opts \\ []) do
    hash = String.downcase(hash)
    limit = min(opts[:limit] || 25, 100)
    before = opts[:before]

    query =
      TokenTransfer
      |> where([tt], tt.chain_id == ^chain_id)
      |> where([tt], tt.from_address == ^hash or tt.to_address == ^hash)
      |> order_by([tt], desc: tt.id)
      |> limit(^(limit + 1))

    query = if before, do: where(query, [tt], tt.id < ^before), else: query

    results = Repo.all(query)

    {transfers, next_cursor} =
      if length(results) > limit do
        transfers = Enum.take(results, limit)
        {transfers, List.last(transfers).id}
      else
        {results, nil}
      end

    {:ok, transfers, next_cursor}
  end
end
