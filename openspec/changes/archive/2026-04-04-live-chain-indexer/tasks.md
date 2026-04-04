## 1. RPC Client

- [x] 1.1 Add `req` dependency to `apps/rexplorer/mix.exs` and run `mix deps.get`
- [x] 1.2 Implement `Rexplorer.RPC.Client` with `call/3` (single JSON-RPC call), `get_latest_block_number/1`, `get_block/2`, `get_block_receipts/2`. Include hex encoding/decoding helpers. Add `@moduledoc` and `@doc` for all public functions
- [x] 1.3 Write tests for `Rexplorer.RPC.Client` using a mock HTTP server (Req test adapter or Bypass). Cover: successful call, RPC error response, network failure, hex encoding/decoding, nil block response
- [x] 1.4 Document RPC client module with `@moduledoc` describing supported methods and usage

## 2. Chain Adapter Updates

- [x] 2.1 Add `poll_interval_ms/0` and `extract_token_transfers/1` callbacks to `Rexplorer.Chain.Adapter` behaviour with `@doc` and `@callback` declarations
- [x] 2.2 Implement `poll_interval_ms/0` in `Rexplorer.Chain.Ethereum` returning `12_000`
- [x] 2.3 Implement `extract_token_transfers/1` in `Rexplorer.Chain.Ethereum` handling: native ETH transfers (from tx value), ERC-20 Transfer events (topic0 = `0xddf252ad...`). Return list of token transfer attr maps
- [x] 2.4 Update existing Ethereum adapter tests for new callbacks. Add tests for: native transfer extraction, ERC-20 transfer extraction, transaction with no transfers, transaction with both native and ERC-20 transfers

## 3. Block Processor

- [x] 3.1 Implement `RexplorerIndexer.BlockProcessor.process_block/3` — takes raw block map, receipts list, adapter module. Returns `%{block: attrs, transactions: [attrs], operations: [attrs], logs: [attrs], token_transfers: [attrs], addresses: [attrs]}`
- [x] 3.2 Implement hex decoding helpers within BlockProcessor: hex string → integer, hex string → binary, address normalization (lowercase)
- [x] 3.3 Implement transaction processing: merge block data + receipt data, decode all hex fields, extract operation via adapter
- [x] 3.4 Implement log extraction from receipts: decode log_index, topics, data, contract_address
- [x] 3.5 Implement token transfer extraction via adapter's `extract_token_transfers/1`
- [x] 3.6 Implement address discovery: collect unique addresses from transactions, logs, and token transfers; deduplicate; set first_seen_at to block timestamp
- [x] 3.7 Write tests for BlockProcessor with fixture data (sample raw block + receipts JSON). Cover: standard block processing, contract creation tx (to=nil), block with multiple transaction types, address deduplication
- [x] 3.8 Document BlockProcessor module and all public functions

## 4. Indexer Worker

- [x] 4.1 Implement `RexplorerIndexer.Worker` GenServer with `init/1` that bootstraps `last_indexed_block` from DB (`MAX(block_number)` for chain) or from RPC head if no blocks exist
- [x] 4.2 Implement `handle_info(:poll, state)` — query latest block number, fetch block if new, verify parent_hash before fetching receipts, process and persist
- [x] 4.3 Implement atomic block persistence: `Repo.transaction` wrapping insert of block, transactions, operations, logs, token_transfers, and address upsert (`on_conflict: :nothing`)
- [x] 4.4 Implement reorg detection: compare new block's parentHash with stored last block hash. On mismatch, log warning with details and halt the worker (don't schedule next poll)
- [x] 4.5 Implement duplicate block handling: catch unique constraint violation on `(chain_id, block_number)`, log debug, skip to next block
- [x] 4.6 Implement catch-up logic: after processing a block, if still behind head, schedule next poll with 0ms delay; otherwise use adapter's `poll_interval_ms/0`
- [x] 4.7 Write tests for Worker: startup bootstrap from DB, startup on fresh chain, poll with new block, poll with no new block, reorg detection halts worker, duplicate block skip. Use mocked RPC responses
- [x] 4.8 Document Worker module with `@moduledoc` explaining the poll loop lifecycle

## 5. Indexer Supervisor

- [x] 5.1 Implement `RexplorerIndexer.Supervisor` as a DynamicSupervisor. On init, query `Rexplorer.Chain.Registry.enabled_adapters/0` and start one Worker per chain
- [x] 5.2 Update `RexplorerIndexer.Application` to start the Supervisor in the supervision tree
- [x] 5.3 Add per-chain RPC configuration to `config/config.exs` and `config/dev.exs` with placeholder URLs
- [x] 5.4 Write test for Supervisor: starts workers for enabled chains

## 6. Documentation

- [x] 6.1 Update `docs/workflows/block-indexing.md` with the final implemented sequence diagram (replace planned diagram with actual flow)
- [x] 6.2 Create `docs/workflows/indexer-startup.md` with Mermaid sequence diagram showing: application boot → supervisor start → registry query → worker start per chain → DB bootstrap → first poll
- [x] 6.3 Create `docs/rpc-client.md` documenting the RPC client API, supported methods, configuration, and error handling

## 7. Final Verification

- [x] 7.1 Run full test suite: `mix test` — all tests pass with zero warnings
- [x] 7.2 Compile with `mix compile --warnings-as-errors`
- [x] 7.3 Verify the indexer starts and connects to a local Ethereum node (manual smoke test if node available, otherwise verify startup/bootstrap logic with mocked RPC)
