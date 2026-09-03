defmodule Rexplorer.Addresses do
  @moduledoc """
  Query module for address records.

  Provides functions to retrieve address metadata and aggregated overviews
  with recent transactions and token transfers, and the upsert the indexer
  uses to record addresses discovered in a block.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Address, Schema.Transaction, Schema.TokenTransfer, Schema.Frame}

  @doc """
  Upserts addresses discovered while indexing a block.

  Unlabelled rows keep the original `ON CONFLICT DO NOTHING` — the hot path,
  run for every address in every block. Rows carrying a role label
  (`Rexplorer.Labels`) instead fill in `label` where it is still NULL, so the
  first observed role wins and re-indexing a block is idempotent.

  Entries are attribute maps with at least `:chain_id`, `:hash` and
  `:first_seen_at`; timestamps are filled in here.
  """
  def upsert_discovered([]), do: :ok

  def upsert_discovered(entries) when is_list(entries) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      Enum.map(entries, fn entry ->
        entry
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    {labelled, unlabelled} = Enum.split_with(entries, &is_binary(Map.get(&1, :label)))

    if unlabelled != [] do
      Repo.insert_all(Address, unlabelled, on_conflict: :nothing)
    end

    if labelled != [] do
      Repo.insert_all(Address, labelled,
        on_conflict:
          from(a in Address,
            update: [set: [label: fragment("COALESCE(?, EXCLUDED.label)", a.label)]]
          ),
        conflict_target: [:chain_id, :hash]
      )
    end

    :ok
  end

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
        # Find transactions where the address is from/to OR is a frame target
        # (EIP-8141 frame txs have to_address=NULL, targets are in frames table)
        frame_tx_ids =
          Frame
          |> where([f], f.chain_id == ^chain_id and f.target == ^hash)
          |> select([f], f.transaction_id)
          |> Repo.all()

        recent_txs =
          Transaction
          |> where([t], t.chain_id == ^chain_id)
          |> where([t], t.from_address == ^hash or t.to_address == ^hash or t.id in ^frame_tx_ids)
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
