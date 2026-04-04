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
  alias Rexplorer.Schema.{Block, Transaction, Operation, Log, TokenTransfer, Address}
  alias RexplorerIndexer.BlockProcessor

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

      case persist_block(result) do
        {:ok, _} ->
          broadcast_new_block(state.chain_id, result)

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

  defp persist_block(result) do
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

  defp schedule_poll(_state, delay) do
    Process.send_after(self(), :poll, delay)
  end
end
