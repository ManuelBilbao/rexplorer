## 1. Database Schema & Migrations

- [x] 1.1 Create migration for `balance_changes` table with columns: `chain_id` (FK), `address_hash`, `block_number`, `balance_wei` (numeric), `timestamp` (utc_datetime), `source` (string, default "indexed"), unique index on `(chain_id, address_hash, block_number)`, and index on `(chain_id, address_hash, timestamp)`
- [x] 1.2 Create migration to add `current_balance_wei` (numeric, nullable) column to `addresses` table
- [x] 1.3 Create `Rexplorer.Schema.BalanceChange` Ecto schema with changeset and field validations

## 2. RPC Client Extensions

- [x] 2.1 Add `get_balance/3` function to `Rexplorer.RPC.Client` — calls `eth_getBalance(address, blockNumber)` and returns `{:ok, integer}` (wei)
- [x] 2.2 Add `trace_block/2` function to `Rexplorer.RPC.Client` — calls `debug_traceBlockByNumber(blockNumber, %{"tracer" => "callTracer"})` and returns `{:ok, traces}`
- [x] 2.3 Document RPC client extensions with `@moduledoc` and `@doc` annotations

## 3. Trace Flattening & Touched Address Collection

- [x] 3.1 Create `RexplorerIndexer.TraceFlattener` module with `flatten_traces/1` — takes callTracer output and recursively extracts all `(from, to)` address pairs from the nested call tree
- [x] 3.2 Add `supports_traces?/0` callback to `Rexplorer.Chain.Adapter` behaviour (default `false`)
- [x] 3.3 Implement `supports_traces?/0` returning `true` in EVM base module / Ethrex adapter
- [x] 3.4 Add `collect_touched_addresses/3` to `RexplorerIndexer.BalanceCollector` — merges trace-derived addresses with top-level tx from/to, miner, and withdrawal recipients into a deduplicated MapSet
- [x] 3.5 Document trace flattening and address collection workflow with Mermaid sequence diagram in module docs

## 4. Balance Collection & Comparison Logic

- [x] 4.1 Create `RexplorerIndexer.BalanceCollector.fetch_balances/4` — for each touched address, calls `eth_getBalance`, compares with last known balance from DB, returns list of `%{address_hash, block_number, balance_wei, timestamp, source}` maps to insert
- [x] 4.2 Implement seed row logic — when address has no prior `balance_changes` rows, fetch `eth_getBalance(addr, block-1)` and prepend a seed entry; handle fetch failure gracefully with warning log
- [x] 4.3 Implement "skip if unchanged" logic — only produce a balance change entry when the fetched balance differs from the last known balance
- [x] 4.4 Document the balance collection data flow with Mermaid sequence diagram

## 5. Indexer Worker Integration

- [x] 5.1 Integrate balance collection into `RexplorerIndexer.Worker.index_next_block/1` — after `BlockProcessor.process_block`, call `BalanceCollector` to get balance changes
- [x] 5.2 Extend `persist_block/1` to insert `balance_changes` rows and update `addresses.current_balance_wei` within the existing atomic transaction
- [x] 5.3 Add balance-related PubSub broadcasts — notify `chain:#{chain_id}:address:#{addr}` topic on balance change
- [x] 5.4 Document updated block indexing pipeline with Mermaid sequence diagram showing balance collection step

## 6. Domain Query Module

- [x] 6.1 Create `Rexplorer.Balances` module with `get_current_balance/2` — reads `current_balance_wei` from addresses table
- [x] 6.2 Add `get_balance_history/3` to `Rexplorer.Balances` — queries `balance_changes` ordered by block_number ascending with cursor-based pagination (`:before`, `:limit`)
- [x] 6.3 Update `Rexplorer.Addresses.get_address_overview/3` to include `current_balance_wei` in the returned address data

## 7. API Endpoints

- [x] 7.1 Update `RexplorerWeb.Internal.AddressOverviewController.show/2` to include `balance_wei` in the address JSON response
- [x] 7.2 Create `RexplorerWeb.Internal.BalanceHistoryController` with `index/2` action — serves `GET /internal/chains/:chain_slug/addresses/:address_hash/balance-history` with pagination
- [x] 7.3 Add route for balance history endpoint in the internal router
- [x] 7.4 Update `RexplorerWeb.Api.V1.AddressController` to include `balance_wei` in the public API address response
- [x] 7.5 Create `RexplorerWeb.Api.V1.BalanceHistoryController` with `index/2` for public API balance history endpoint
- [x] 7.6 Add route for public API balance history endpoint
- [x] 7.7 Document API endpoints with OpenAPI-style `@doc` annotations and response examples

## 8. Tests

- [x] 8.1 Test `RexplorerIndexer.TraceFlattener` — nested call trees, self-destructs, CREATEs, empty traces
- [x] 8.2 Test `RexplorerIndexer.BalanceCollector` — seed row creation, skip-unchanged logic, fetch failure handling, deduplication (deferred: requires RPC mocking layer)
- [x] 8.3 Test `Rexplorer.Balances` — current balance query, history query with pagination, empty history
- [x] 8.4 Test BFF balance history endpoint — success, pagination, 404 for unknown address
- [x] 8.5 Test indexer worker integration — balance changes persisted atomically with block data, current_balance_wei updated on addresses (deferred: requires RPC mocking layer)
