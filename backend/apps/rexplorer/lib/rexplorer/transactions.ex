defmodule Rexplorer.Transactions do
  @moduledoc """
  Query module for transaction records.

  Provides functions to retrieve single transactions (with optional preloaded
  associations) and paginated lists with address filtering.
  Uses semantic cursor pagination with (block_number, transaction_index).
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Transaction}

  @default_limit 25
  @max_limit 100

  @doc "Returns a single transaction by chain_id and hash."
  def get_transaction(chain_id, hash) do
    hash = String.downcase(hash)

    case Repo.get_by(Transaction, chain_id: chain_id, hash: hash) do
      nil -> {:error, :not_found}
      tx -> {:ok, Repo.preload(tx, :block)}
    end
  end

  @doc """
  Returns a transaction with all associations preloaded:
  operations, token_transfers, logs, and block.
  Used by the BFF for the transaction detail page.
  """
  def get_full_transaction(chain_id, hash) do
    hash = String.downcase(hash)

    case Repo.get_by(Transaction, chain_id: chain_id, hash: hash) do
      nil ->
        {:error, :not_found}

      tx ->
        tx =
          Repo.preload(tx, [
            :block,
            [operations: from(o in Rexplorer.Schema.Operation, order_by: o.operation_index)],
            :token_transfers,
            [logs: from(l in Rexplorer.Schema.Log, order_by: l.log_index)],
            [frames: from(f in Rexplorer.Schema.Frame, order_by: f.frame_index)]
          ])

        # Load cross-chain links
        cross_chain_links = load_cross_chain_links(chain_id, hash)

        {:ok, tx, cross_chain_links}
    end
  end

  @doc """
  Returns a paginated list of transactions for a chain.

  Options:
  - `:address` — filter by address (as sender or recipient)
  - `:block_number` — filter to a specific block (exact match)
  - `:before_block` — block_number part of cursor
  - `:before_index` — transaction_index part of cursor
  - `:limit` — max results (default 25, max 100)
  """
  def list_transactions(chain_id, opts \\ []) do
    limit = min(opts[:limit] || @default_limit, @max_limit)
    address = opts[:address]
    block_number = opts[:block_number]
    before_block = opts[:before_block]
    before_index = opts[:before_index]

    query =
      from t in Transaction,
        join: b in assoc(t, :block),
        where: t.chain_id == ^chain_id,
        order_by: [desc: b.block_number, desc: t.transaction_index],
        limit: ^(limit + 1),
        preload: [block: b]

    query =
      if block_number do
        where(query, [t, b], b.block_number == ^block_number)
      else
        query
      end

    query =
      if address do
        addr = String.downcase(address)
        where(query, [t], t.from_address == ^addr or t.to_address == ^addr)
      else
        query
      end

    query =
      if before_block && before_index do
        where(query, [t, b],
          b.block_number < ^before_block or
            (b.block_number == ^before_block and t.transaction_index < ^before_index)
        )
      else
        if before_block do
          where(query, [t, b], b.block_number < ^before_block)
        else
          query
        end
      end

    results = Repo.all(query)

    {txs, next_cursor} =
      if length(results) > limit do
        txs = Enum.take(results, limit)
        last = List.last(txs)
        last_block = last.block

        {txs,
         %{before_block: last_block.block_number, before_index: last.transaction_index}}
      else
        {results, nil}
      end

    {:ok, txs, next_cursor}
  end

  defp load_cross_chain_links(chain_id, tx_hash) do
    import Ecto.Query

    Rexplorer.Schema.CrossChainLink
    |> where([l], (l.source_chain_id == ^chain_id and l.source_tx_hash == ^tx_hash) or
                  (l.destination_chain_id == ^chain_id and l.destination_tx_hash == ^tx_hash))
    |> Repo.all()
  end
end
