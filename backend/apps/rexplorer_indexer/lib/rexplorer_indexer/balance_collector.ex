defmodule RexplorerIndexer.BalanceCollector do
  @moduledoc """
  Collects native-token balance changes for all addresses touched in a block.

  This module handles the full balance-tracking pipeline:

  1. **Collect touched addresses** — from traces (if supported) merged with
     top-level transaction participants, miner, and withdrawal recipients.
  2. **Fetch balances** — call `eth_getBalance` for each touched address.
  3. **Compare and filter** — only produce entries where the balance actually changed.
  4. **Seed first-seen addresses** — fetch the balance at block N-1 to establish
     a baseline for the chart.

  ## Data Flow

  ```mermaid
  sequenceDiagram
      participant W as Indexer Worker
      participant BC as BalanceCollector
      participant RPC as RPC Node
      participant DB as Database

      W->>BC: collect_touched_addresses(adapter, rpc_url, raw_block)
      alt Adapter supports traces
          BC->>RPC: debug_traceBlockByNumber(N, {callTracer})
          BC-->>BC: TraceFlattener.flatten_traces(result)
      end
      BC-->>BC: Merge trace addrs + tx from/to + miner + withdrawals
      BC-->>W: MapSet of touched addresses

      W->>BC: fetch_balances(rpc_url, chain_id, block_number, touched, timestamp)
      loop Each touched address
          BC->>RPC: eth_getBalance(addr, N)
          BC->>DB: Last known balance for addr?
          alt First time seen
              BC->>RPC: eth_getBalance(addr, N-1)
              Note over BC: Prepend seed row
          end
          alt Balance changed
              Note over BC: Add balance_changes entry
          end
      end
      BC-->>W: {balance_changes, address_updates}
  ```
  """

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Rexplorer.{Repo, RPC.Client}
  alias Rexplorer.Schema.BalanceChange
  alias RexplorerIndexer.TraceFlattener

  @doc """
  Collects all addresses whose balance may have changed in a block.

  When the adapter supports traces, calls `debug_traceBlockByNumber` to
  discover internal call participants. Always includes top-level tx from/to,
  the block miner, and withdrawal recipients.

  Returns a `MapSet` of lowercase hex addresses.
  """
  @spec collect_touched_addresses(module(), String.t(), map()) :: {MapSet.t(String.t()), list()}
  def collect_touched_addresses(adapter, rpc_url, raw_block) do
    block_number = Client.hex_to_integer(raw_block["number"])

    {trace_addresses, raw_traces} =
      if adapter.supports_traces?() do
        case Client.trace_block(rpc_url, block_number) do
          {:ok, traces} when is_list(traces) ->
            {TraceFlattener.flatten_traces(traces), traces}

          {:error, reason} ->
            Logger.warning(
              "[BalanceCollector] Trace call failed for block #{block_number}: #{inspect(reason)}, falling back to tx-only"
            )

            {MapSet.new(), []}
        end
      else
        {MapSet.new(), []}
      end

    tx_addresses =
      raw_block
      |> Map.get("transactions", [])
      |> Enum.reduce(MapSet.new(), fn tx, acc ->
        acc
        |> maybe_add(tx["from"])
        |> maybe_add(tx["to"])
      end)

    miner_address = MapSet.new([raw_block["miner"]] |> Enum.reject(&is_nil/1) |> Enum.map(&String.downcase/1))

    withdrawal_addresses =
      raw_block
      |> Map.get("withdrawals", [])
      |> Enum.reduce(MapSet.new(), fn w, acc -> maybe_add(acc, w["address"]) end)

    all_addresses =
      trace_addresses
      |> MapSet.union(tx_addresses)
      |> MapSet.union(miner_address)
      |> MapSet.union(withdrawal_addresses)

    {all_addresses, raw_traces}
  end

  @doc """
  Fetches balances for all touched addresses and returns change entries.

  For each address:
  1. Calls `eth_getBalance(address, block_number)` to get the current balance.
  2. Looks up the last known balance from `balance_changes` in the DB.
  3. If the address is first-seen, fetches `eth_getBalance(address, block_number - 1)`
     as a seed row.
  4. Only returns entries where the balance actually changed.

  Returns `{balance_change_entries, address_balance_updates}` where:
  - `balance_change_entries` is a list of maps ready for `Repo.insert_all`
  - `address_balance_updates` is a list of `{address_hash, balance_wei}` tuples
    for updating `addresses.current_balance_wei`
  """
  @spec fetch_balances(String.t(), integer(), integer(), MapSet.t(String.t()), DateTime.t()) ::
          {list(map()), list({String.t(), Decimal.t()})}
  def fetch_balances(rpc_url, chain_id, block_number, touched_addresses, block_timestamp) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    addresses = MapSet.to_list(touched_addresses)

    # Batch fetch all balances at block_number
    balance_results = Client.get_balances(rpc_url, addresses, block_number)

    # Find first-seen addresses (no prior balance_changes rows)
    first_seen = Enum.filter(addresses, fn addr -> get_last_known_balance(chain_id, addr) == nil end)

    # Batch fetch seed balances at block_number - 1 for first-seen addresses
    seed_results =
      if first_seen != [] and block_number > 0 do
        Client.get_balances(rpc_url, first_seen, block_number - 1)
      else
        %{}
      end

    # Process each address
    Enum.reduce(addresses, {[], []}, fn address_hash, {changes_acc, updates_acc} ->
      case Map.get(balance_results, address_hash) do
        {:ok, balance_int} ->
          balance_wei = Decimal.new(balance_int)
          last_known = get_last_known_balance(chain_id, address_hash)
          is_first_seen = last_known == nil

          seed_entries =
            if is_first_seen do
              case Map.get(seed_results, address_hash) do
                {:ok, seed_int} ->
                  [%{
                    chain_id: chain_id,
                    address_hash: address_hash,
                    block_number: block_number - 1,
                    balance_wei: Decimal.new(seed_int),
                    timestamp: block_timestamp,
                    source: "seed",
                    inserted_at: now,
                    updated_at: now
                  }]

                _ ->
                  Logger.warning("[BalanceCollector] Seed fetch failed for #{address_hash} at block #{block_number - 1}")
                  []
              end
            else
              []
            end

          if balance_changed?(balance_wei, last_known, is_first_seen) do
            entry = %{
              chain_id: chain_id,
              address_hash: address_hash,
              block_number: block_number,
              balance_wei: balance_wei,
              timestamp: block_timestamp,
              source: "indexed",
              inserted_at: now,
              updated_at: now
            }

            {seed_entries ++ [entry] ++ changes_acc, [{address_hash, balance_wei} | updates_acc]}
          else
            if seed_entries != [] do
              seed_balance = hd(seed_entries).balance_wei
              {seed_entries ++ changes_acc, [{address_hash, seed_balance} | updates_acc]}
            else
              {changes_acc, updates_acc}
            end
          end

        _ ->
          {changes_acc, updates_acc}
      end
    end)
  end

  # Returns the last known balance for an address, or nil if first-seen.
  defp get_last_known_balance(chain_id, address_hash) do
    query =
      from bc in BalanceChange,
        where: bc.chain_id == ^chain_id and bc.address_hash == ^address_hash,
        order_by: [desc: bc.block_number],
        limit: 1,
        select: bc.balance_wei

    Repo.one(query)
  end

  # Checks whether the balance has changed from the last known value.
  defp balance_changed?(_balance_wei, nil, true) do
    # First-seen address: always record block N balance
    true
  end

  defp balance_changed?(balance_wei, last_known, _is_first_seen) do
    not Decimal.equal?(balance_wei, last_known)
  end

  defp maybe_add(set, nil), do: set
  defp maybe_add(set, ""), do: set
  defp maybe_add(set, address), do: MapSet.put(set, String.downcase(address))
end
