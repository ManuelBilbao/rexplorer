defmodule Rexplorer.Search do
  @moduledoc """
  Classifies search input and returns matching results.

  Supports searching by transaction hash, block number, and address.
  Can be scoped to a specific chain or search across all chains.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema}

  @doc """
  Classifies the input and returns matching results.

  Options:
  - `:chain_id` — scope search to a specific chain (optional)

  Returns `{:ok, %{type: atom, results: list}}`.
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

    results = Repo.all(query)
    {:ok, %{type: :transaction, results: results}}
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
