defmodule Rexplorer.Search do
  @moduledoc """
  Classifies search input and returns matching results.

  Supports searching by transaction hash, userOpHash, block number, and
  address. Can be scoped to a specific chain or search across all chains.

  A 66-character hex string is looked up as a transaction hash first — the
  common case, which must not pay for the fallback — and only when that misses
  is it retried as an ERC-4337 userOpHash.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema}

  @doc """
  Classifies the input and returns matching results.

  Options:
  - `:chain_id` — scope search to a specific chain (optional)

  Returns `{:ok, %{type: atom, results: list}}`. The type is one of
  `:transaction`, `:user_operation`, `:address`, `:block_number` or
  `:unknown`.
  """
  def query(input, opts \\ []) do
    input = String.trim(input)
    chain_id = opts[:chain_id]

    cond do
      tx_hash?(input) -> search_transaction(input, chain_id)
      address?(input) -> search_address(input, chain_id)
      block_number?(input) -> search_block(String.to_integer(input), chain_id)
      true -> {:ok, %{type: :unknown, results: []}}
    end
  end

  defp tx_hash?(input), do: String.match?(input, ~r/^0x[0-9a-fA-F]{64}$/)
  defp address?(input), do: String.match?(input, ~r/^0x[0-9a-fA-F]{40}$/)
  defp block_number?(input), do: String.match?(input, ~r/^\d+$/)

  defp search_transaction(hash, chain_id) do
    hash = String.downcase(hash)

    query =
      from t in Schema.Transaction,
        join: b in assoc(t, :block),
        where: t.hash == ^hash,
        preload: [block: b],
        select: t

    query = if chain_id, do: where(query, [t], t.chain_id == ^chain_id), else: query

    case Repo.all(query) do
      [] -> search_user_operation(hash, chain_id)
      results -> {:ok, %{type: :transaction, results: results}}
    end
  end

  # A hash that is not a transaction may be an ERC-4337 userOpHash. The
  # existence predicate is what lets Postgres use the partial index on
  # `op_extra->>'user_op_hash'`; without it the planner falls back to a scan.
  defp search_user_operation(hash, chain_id) do
    hash = String.downcase(hash)

    query =
      from o in Schema.Operation,
        join: t in assoc(o, :transaction),
        join: b in assoc(t, :block),
        where: fragment("? \\? ?", o.op_extra, "user_op_hash"),
        where: fragment("?->>'user_op_hash' = ?", o.op_extra, ^hash),
        order_by: [asc: o.operation_index],
        preload: [transaction: {t, block: b}],
        select: o

    query = if chain_id, do: where(query, [o], o.chain_id == ^chain_id), else: query

    results = Repo.all(query)
    {:ok, %{type: :user_operation, results: results}}
  end

  defp search_address(hash, chain_id) do
    hash = String.downcase(hash)

    query = from a in Schema.Address, where: a.hash == ^hash
    query = if chain_id, do: where(query, [a], a.chain_id == ^chain_id), else: query

    results = Repo.all(query)
    {:ok, %{type: :address, results: results}}
  end

  defp search_block(number, chain_id) do
    query = from b in Schema.Block, where: b.block_number == ^number
    query = if chain_id, do: where(query, [b], b.chain_id == ^chain_id), else: query

    results = Repo.all(query)
    {:ok, %{type: :block_number, results: results}}
  end
end
