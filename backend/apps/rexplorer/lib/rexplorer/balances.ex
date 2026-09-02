defmodule Rexplorer.Balances do
  @moduledoc """
  Query module for native-token balance data.

  Provides functions to retrieve current balances and historical balance
  series for charting.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Address, Schema.BalanceChange}

  @doc """
  Returns the current native-token balance for an address.

  Reads from the denormalized `current_balance_wei` field on the `addresses`
  table for fast lookups.
  """
  def get_current_balance(chain_id, hash) do
    hash = String.downcase(hash)

    query =
      from a in Address,
        where: a.chain_id == ^chain_id and a.hash == ^hash,
        select: {a.current_balance_wei}

    case Repo.one(query) do
      nil -> {:error, :not_found}
      {balance} -> {:ok, balance}
    end
  end

  @doc """
  Returns a time-ordered list of balance data points for charting.

  Each entry is a map with `block_number`, `balance_wei`, and `timestamp`.
  Results are ordered by `block_number` ascending.

  ## Options

  - `:before` — block_number cursor (only return entries with block_number < before)
  - `:limit` — max results (default 500, max 2000)
  """
  def get_balance_history(chain_id, hash, opts \\ []) do
    hash = String.downcase(hash)
    limit = min(opts[:limit] || 500, 2000)
    before = opts[:before]

    query =
      from bc in BalanceChange,
        where: bc.chain_id == ^chain_id and bc.address_hash == ^hash,
        order_by: [asc: bc.block_number],
        limit: ^(limit + 1),
        select: %{
          block_number: bc.block_number,
          balance_wei: bc.balance_wei,
          timestamp: bc.timestamp
        }

    query = if before, do: where(query, [bc], bc.block_number < ^before), else: query

    results = Repo.all(query)

    {entries, next_cursor} =
      if length(results) > limit do
        entries = Enum.take(results, limit)
        {entries, List.last(entries).block_number}
      else
        {results, nil}
      end

    {:ok, entries, next_cursor}
  end
end
