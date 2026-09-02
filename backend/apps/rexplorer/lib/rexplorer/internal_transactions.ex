defmodule Rexplorer.InternalTransactions do
  @moduledoc """
  Query module for internal transactions.

  Uses the two-query union pattern for address lookups: separate indexed
  queries on `from_address` and `to_address`, merged and deduplicated in
  Elixir. This avoids the `OR` index problem in PostgreSQL where a single
  `WHERE from = ? OR to = ?` query can't efficiently use both indexes.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.InternalTransaction}

  @doc """
  Returns paginated internal transactions where the address is sender or recipient.

  ## Options

  - `:before` — block_number cursor
  - `:limit` — max results (default 25, max 100)
  """
  def list_by_address(chain_id, hash, opts \\ []) do
    hash = String.downcase(hash)
    limit = min(opts[:limit] || 25, 100)
    before = opts[:before]

    # Two separate queries for index efficiency
    from_query =
      InternalTransaction
      |> where([it], it.chain_id == ^chain_id and it.from_address == ^hash)
      |> apply_cursor(before)
      |> order_by([it], desc: it.block_number, desc: it.transaction_index, desc: it.trace_index)
      |> limit(^(limit + 1))

    to_query =
      InternalTransaction
      |> where([it], it.chain_id == ^chain_id and it.to_address == ^hash)
      |> apply_cursor(before)
      |> order_by([it], desc: it.block_number, desc: it.transaction_index, desc: it.trace_index)
      |> limit(^(limit + 1))

    from_results = Repo.all(from_query)
    to_results = Repo.all(to_query)

    # Merge, dedup by id, sort, paginate
    merged =
      (from_results ++ to_results)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(&{&1.block_number, &1.transaction_index, &1.trace_index}, :desc)

    {entries, next_cursor} =
      if length(merged) > limit do
        entries = Enum.take(merged, limit)
        {entries, List.last(entries).block_number}
      else
        {Enum.take(merged, limit), nil}
      end

    {:ok, entries, next_cursor}
  end

  defp apply_cursor(query, nil), do: query
  defp apply_cursor(query, before), do: where(query, [it], it.block_number < ^before)
end
