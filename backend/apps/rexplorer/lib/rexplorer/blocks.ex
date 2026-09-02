defmodule Rexplorer.Blocks do
  @moduledoc """
  Query module for block records.

  Provides functions to retrieve and paginate blocks with transaction counts.
  Uses semantic cursor pagination with block_number as the cursor.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Block}

  @default_limit 25
  @max_limit 100

  @doc """
  Returns a single block by chain_id and block_number.

  Includes a virtual `transaction_count` via subquery.
  """
  def get_block(chain_id, block_number) do
    query =
      from b in Block,
        where: b.chain_id == ^chain_id and b.block_number == ^block_number,
        left_join: t in assoc(b, :transactions),
        group_by: b.id,
        select_merge: %{transaction_count: count(t.id)}

    case Repo.one(query) do
      nil -> {:error, :not_found}
      block -> {:ok, block}
    end
  end

  @doc """
  Returns a paginated list of blocks for a chain.

  Options:
  - `:before` — block_number cursor (return blocks before this number)
  - `:limit` — max results (default 25, max 100)
  """
  def list_blocks(chain_id, opts \\ []) do
    limit = min(opts[:limit] || @default_limit, @max_limit)
    before = opts[:before]

    query =
      from b in Block,
        where: b.chain_id == ^chain_id,
        left_join: t in assoc(b, :transactions),
        group_by: b.id,
        order_by: [desc: b.block_number],
        limit: ^(limit + 1),
        select_merge: %{transaction_count: count(t.id)}

    query =
      if before do
        where(query, [b], b.block_number < ^before)
      else
        query
      end

    results = Repo.all(query)

    {blocks, next_cursor} =
      if length(results) > limit do
        blocks = Enum.take(results, limit)
        last = List.last(blocks)
        {blocks, last.block_number}
      else
        {results, nil}
      end

    {:ok, blocks, next_cursor}
  end
end
