defmodule RexplorerIndexer.Worker do
  @moduledoc """
  Per-chain indexer worker that keeps the database in sync with the chain head.

  Each worker is a GenServer that runs a poll loop:

  1. Query the RPC node for the latest block number
  2. If a new block is available, fetch it and its receipts
  3. Verify parent_hash continuity (reorg detection)
  4. Process the block through `BlockProcessor`
  5. Persist all data atomically in a single DB transaction
  6. Schedule the next poll (immediately if behind, after interval if caught up)

  On startup, the worker bootstraps its `last_indexed_block` from the database
  by querying `MAX(block_number)` for its chain. If no blocks exist, it starts
  from the chain's current head.
  """

  use GenServer
  require Logger

  import Ecto.Query, only: [from: 2]

  alias Rexplorer.{Repo, RPC.Client}
  alias Rexplorer.Schema.{Block, Batch, Transaction, Operation, Log, TokenTransfer, Address, BalanceChange, InternalTransaction, Frame}
  alias RexplorerIndexer.{BlockProcessor, BalanceCollector, TraceFlattener}

  defstruct [:chain_id, :adapter, :rpc_url, :last_indexed_block, :last_block_hash, :polling]

  @doc "Starts the worker for the given chain adapter and RPC URL."
  def start_link(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    rpc_url = Keyword.fetch!(opts, :rpc_url)
    name = Keyword.get(opts, :name, via_name(adapter.chain_id()))
    GenServer.start_link(__MODULE__, {adapter, rpc_url}, name: name)
  end

  defp via_name(chain_id), do: {:global, {__MODULE__, chain_id}}

  @impl true
  def init({adapter, rpc_url}) do
    chain_id = adapter.chain_id()
    Logger.info("[Indexer] Starting worker for chain #{chain_id} (#{rpc_url})")

    state = %__MODULE__{
      chain_id: chain_id,
      adapter: adapter,
      rpc_url: rpc_url,
      last_indexed_block: nil,
      last_block_hash: nil,
      polling: true
    }

    {:ok, state, {:continue, :bootstrap}}
  end

  @impl true
  def handle_continue(:bootstrap, state) do
    {last_block, last_hash} = bootstrap_from_db(state.chain_id)

    state =
      case last_block do
        nil ->
          # Fresh chain — start from current head
          case Client.get_latest_block_number(state.rpc_url) do
            {:ok, head} ->
              Logger.info("[Indexer] Chain #{state.chain_id}: no blocks in DB, starting from head #{head}")
              %{state | last_indexed_block: head - 1, last_block_hash: nil}

            {:error, reason} ->
              Logger.error("[Indexer] Chain #{state.chain_id}: failed to get head: #{inspect(reason)}")
              %{state | last_indexed_block: 0, last_block_hash: nil}
          end

        block_number ->
          Logger.info("[Indexer] Chain #{state.chain_id}: resuming from block #{block_number}")
          %{state | last_indexed_block: block_number, last_block_hash: last_hash}
      end

    schedule_poll(state, 0)
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, %{polling: false} = state), do: {:noreply, state}

  def handle_info(:poll, state) do
    case index_next_block(state) do
      {:ok, new_state, :caught_up} ->
        schedule_poll(new_state, new_state.adapter.poll_interval_ms())
        {:noreply, new_state}

      {:ok, new_state, :more_blocks} ->
        schedule_poll(new_state, 0)
        {:noreply, new_state}

      {:error, :reorg_detected, state} ->
        Logger.warning("[Indexer] Chain #{state.chain_id}: REORG DETECTED — halting worker")
        {:noreply, %{state | polling: false}}

      {:error, :already_indexed, state} ->
        Logger.debug("[Indexer] Chain #{state.chain_id}: block already indexed, skipping")
        schedule_poll(state, state.adapter.poll_interval_ms())
        {:noreply, state}

      {:error, reason, state} ->
        Logger.error("[Indexer] Chain #{state.chain_id}: error — #{inspect(reason)}")
        schedule_poll(state, state.adapter.poll_interval_ms())
        {:noreply, state}
    end
  end

  # Core indexing logic

  defp index_next_block(state) do
    target_block = state.last_indexed_block + 1

    with {:ok, head} <- Client.get_latest_block_number(state.rpc_url),
         true <- target_block <= head || :caught_up,
         {:ok, raw_block} when not is_nil(raw_block) <- Client.get_block(state.rpc_url, target_block),
         :ok <- verify_parent_hash(raw_block, state),
         {:ok, receipts} <- Client.get_block_receipts(state.rpc_url, target_block) do
      result = BlockProcessor.process_block(raw_block, receipts, state.adapter)

      # Collect balance changes and internal transactions from traces
      {touched, raw_traces} = BalanceCollector.collect_touched_addresses(state.adapter, state.rpc_url, raw_block)
      block_timestamp = parse_block_timestamp(raw_block["timestamp"])

      {balance_changes, address_updates} =
        BalanceCollector.fetch_balances(state.rpc_url, state.chain_id, target_block, touched, block_timestamp)

      # Extract internal transactions from the same trace data
      internal_txs = build_internal_transactions(raw_traces, state.chain_id, target_block)

      case persist_block(result, balance_changes, address_updates, internal_txs) do
        {:ok, _} ->
          broadcast_new_block(state.chain_id, result)
          broadcast_balance_changes(state.chain_id, address_updates)
          fetch_batch_info(state, target_block)

          new_state = %{state |
            last_indexed_block: target_block,
            last_block_hash: raw_block["hash"]
          }

          status = if target_block < head, do: :more_blocks, else: :caught_up
          {:ok, new_state, status}

        {:error, %{errors: [_ | _]} = changeset} ->
          {:error, changeset, state}

        {:error, :already_indexed} ->
          new_state = %{state |
            last_indexed_block: target_block,
            last_block_hash: raw_block["hash"]
          }
          {:error, :already_indexed, new_state}
      end
    else
      :caught_up ->
        {:ok, state, :caught_up}

      {:ok, nil} ->
        {:ok, state, :caught_up}

      {:error, :reorg_detected} ->
        {:error, :reorg_detected, state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  defp verify_parent_hash(_raw_block, %{last_block_hash: nil}), do: :ok

  defp verify_parent_hash(raw_block, %{last_block_hash: expected_hash, chain_id: chain_id}) do
    parent_hash = raw_block["parentHash"]

    if parent_hash == expected_hash do
      :ok
    else
      block_number = raw_block["number"]

      Logger.warning(
        "[Indexer] Chain #{chain_id}: reorg at block #{block_number}. " <>
          "Expected parent #{expected_hash}, got #{parent_hash}"
      )

      {:error, :reorg_detected}
    end
  end

  defp persist_block(result, balance_changes, address_updates, internal_txs) do
    Repo.transaction(fn ->
      # Insert block
      block =
        %Block{}
        |> Block.changeset(result.block)
        |> Repo.insert!()

      # Insert transactions and collect ID mappings
      tx_map =
        result.transactions
        |> Enum.map(fn tx_attrs ->
          tx =
            %Transaction{}
            |> Transaction.changeset(Map.put(tx_attrs, :block_id, block.id))
            |> Repo.insert!()

          {tx_attrs.hash, tx.id}
        end)
        |> Map.new()

      # Insert frames (EIP-8141 frame transactions)
      Enum.each(Map.get(result, :frames, []), fn frame_attrs ->
        tx_id = Map.get(tx_map, frame_attrs[:tx_hash])

        %Frame{}
        |> Frame.changeset(frame_attrs |> Map.put(:transaction_id, tx_id) |> Map.delete(:tx_hash))
        |> Repo.insert!()
      end)

      # Insert operations (tx_hash propagated by BlockProcessor)
      Enum.each(result.operations, fn op_attrs ->
        tx_id = Map.get(tx_map, op_attrs[:tx_hash])

        %Operation{}
        |> Operation.changeset(op_attrs |> Map.put(:transaction_id, tx_id) |> Map.delete(:tx_hash))
        |> Repo.insert!()
      end)

      # Insert logs (tx_hash propagated by BlockProcessor)
      Enum.each(result.logs, fn log_attrs ->
        tx_id = Map.get(tx_map, log_attrs[:tx_hash])

        %Log{}
        |> Log.changeset(log_attrs |> Map.put(:transaction_id, tx_id) |> Map.delete(:tx_hash))
        |> Repo.insert!()
      end)

      # Insert token transfers (tx_hash propagated by BlockProcessor)
      Enum.each(result.token_transfers, fn xfer_attrs ->
        tx_id = Map.get(tx_map, xfer_attrs[:tx_hash])

        %TokenTransfer{}
        |> TokenTransfer.changeset(xfer_attrs |> Map.put(:transaction_id, tx_id) |> Map.delete(:tx_hash))
        |> Repo.insert!()
      end)

      # Upsert addresses (on_conflict: :nothing — first insert wins)
      if result.addresses != [] do
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        address_entries =
          Enum.map(result.addresses, fn addr ->
            addr
            |> Map.put(:inserted_at, now)
            |> Map.put(:updated_at, now)
          end)

        Repo.insert_all(Address, address_entries, on_conflict: :nothing)
      end

      # Ensure addresses from balance tracking exist in the addresses table
      # (traces may discover addresses not in top-level tx from/to)
      if address_updates != [] do
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        trace_address_entries =
          Enum.map(address_updates, fn {address_hash, _balance_wei} ->
            %{
              chain_id: result.block.chain_id,
              hash: address_hash,
              is_contract: false,
              first_seen_at: result.block.timestamp,
              inserted_at: now,
              updated_at: now
            }
          end)

        Repo.insert_all(Address, trace_address_entries, on_conflict: :nothing)
      end

      # Insert balance changes
      if balance_changes != [] do
        Repo.insert_all(BalanceChange, balance_changes, on_conflict: :nothing)
      end

      # Insert internal transactions
      if internal_txs != [] do
        Repo.insert_all(InternalTransaction, internal_txs, on_conflict: :nothing)
      end

      # Update current_balance_wei on addresses
      Enum.each(address_updates, fn {address_hash, balance_wei} ->
        from(a in Address,
          where: a.chain_id == ^result.block.chain_id and a.hash == ^address_hash
        )
        |> Repo.update_all(set: [current_balance_wei: balance_wei, updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)])
      end)

      :ok
    end)
  rescue
    e in Ecto.ConstraintError ->
      if String.contains?(to_string(e.message || ""), "unique") ||
           String.contains?(to_string(e.constraint || ""), "block") do
        {:error, :already_indexed}
      else
        reraise e, __STACKTRACE__
      end
  end

  # Helpers

  defp bootstrap_from_db(chain_id) do
    query =
      from b in Block,
        where: b.chain_id == ^chain_id,
        order_by: [desc: b.block_number],
        limit: 1,
        select: {b.block_number, b.hash}

    case Repo.one(query) do
      nil -> {nil, nil}
      {number, hash} -> {number, hash}
    end
  end

  defp broadcast_new_block(chain_id, result) do
    block = result.block

    block_summary = %{
      block_number: block.block_number,
      hash: block.hash,
      timestamp: to_string(block.timestamp),
      transaction_count: length(result.transactions),
      gas_used: block.gas_used
    }

    Phoenix.PubSub.broadcast(Rexplorer.PubSub, "chain:#{chain_id}:blocks", {:new_block, block_summary})

    # Broadcast to address-specific topics
    addresses_involved =
      result.transactions
      |> Enum.flat_map(fn tx -> [tx.from_address, tx.to_address] end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    Enum.each(addresses_involved, fn addr ->
      Phoenix.PubSub.broadcast(
        Rexplorer.PubSub,
        "chain:#{chain_id}:address:#{addr}",
        {:new_transaction, %{block_number: block.block_number}}
      )
    end)
  rescue
    _ -> :ok
  end

  # Batch tracking for Ethrex (ZK rollup) chains

  defp fetch_batch_info(%{adapter: adapter, rpc_url: rpc_url, chain_id: chain_id}, block_number) do
    if adapter.chain_type() == :zk_rollup do
      try do
        case Client.ethrex_get_batch_by_block(rpc_url, block_number) do
          {:ok, nil} ->
            :ok

          {:ok, batch_data} when is_map(batch_data) ->
            batch_number = batch_data["batch_number"] || Client.hex_to_integer(batch_data["number"])
            first_block = Client.hex_to_integer(batch_data["first_block"])
            last_block = Client.hex_to_integer(batch_data["last_block"])
            commit_tx = batch_data["commit_tx_hash"] || batch_data["commit_tx"]
            verify_tx = batch_data["verify_tx_hash"] || batch_data["verify_tx"]

            status =
              cond do
                verify_tx -> :verified
                commit_tx -> :committed
                true -> :sealed
              end

            if batch_number do
              # Update block's chain_extra with batch_number
              update_block_batch_number(chain_id, block_number, batch_number)

              # Upsert batch record
              upsert_batch(chain_id, batch_number, first_block, last_block, status, commit_tx, verify_tx)
            end

          {:error, _} ->
            :ok
        end
      rescue
        e ->
          Logger.debug("[Indexer] Chain #{chain_id}: batch fetch failed for block #{block_number}: #{Exception.message(e)}")
      end
    end
  end

  defp update_block_batch_number(chain_id, block_number, batch_number) do
    query =
      from b in Block,
        where: b.chain_id == ^chain_id and b.block_number == ^block_number

    case Repo.one(query) do
      nil -> :ok
      block ->
        chain_extra = Map.put(block.chain_extra || %{}, "batch_number", batch_number)
        block |> Ecto.Changeset.change(%{chain_extra: chain_extra}) |> Repo.update()
    end
  rescue
    _ -> :ok
  end

  defp upsert_batch(chain_id, batch_number, first_block, last_block, status, commit_tx, verify_tx) do
    case Repo.get_by(Batch, chain_id: chain_id, batch_number: batch_number) do
      nil ->
        %Batch{}
        |> Batch.changeset(%{
          chain_id: chain_id,
          batch_number: batch_number,
          first_block: first_block,
          last_block: last_block,
          status: status,
          commit_tx_hash: commit_tx,
          verify_tx_hash: verify_tx
        })
        |> Repo.insert()

      existing ->
        # Update if status has progressed
        attrs = %{}
        attrs = if status_rank(status) > status_rank(existing.status), do: Map.put(attrs, :status, status), else: attrs
        attrs = if commit_tx && !existing.commit_tx_hash, do: Map.put(attrs, :commit_tx_hash, commit_tx), else: attrs
        attrs = if verify_tx && !existing.verify_tx_hash, do: Map.put(attrs, :verify_tx_hash, verify_tx), else: attrs

        if attrs != %{} do
          existing |> Ecto.Changeset.change(attrs) |> Repo.update()
        else
          {:ok, existing}
        end
    end
  rescue
    _ -> :ok
  end

  defp status_rank(:sealed), do: 0
  defp status_rank(:committed), do: 1
  defp status_rank(:verified), do: 2
  defp status_rank(_), do: 0

  defp build_internal_transactions(raw_traces, chain_id, block_number) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    raw_traces
    |> TraceFlattener.flatten_to_entries()
    |> Enum.map(fn entry ->
      entry
      |> Map.put(:chain_id, chain_id)
      |> Map.put(:block_number, block_number)
      |> Map.put(:inserted_at, now)
      |> Map.put(:updated_at, now)
    end)
  end

  defp broadcast_balance_changes(chain_id, address_updates) do
    Enum.each(address_updates, fn {address_hash, balance_wei} ->
      Phoenix.PubSub.broadcast(
        Rexplorer.PubSub,
        "chain:#{chain_id}:address:#{address_hash}",
        {:balance_changed, %{balance_wei: to_string(balance_wei)}}
      )
    end)
  rescue
    _ -> :ok
  end

  defp parse_block_timestamp(hex_timestamp) do
    unix = Client.hex_to_integer(hex_timestamp)
    DateTime.from_unix!(unix) |> DateTime.truncate(:second)
  end

  defp schedule_poll(_state, delay) do
    Process.send_after(self(), :poll, delay)
  end
end
