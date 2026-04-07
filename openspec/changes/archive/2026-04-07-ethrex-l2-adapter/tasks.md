## 1. Database: Batches Table

- [x] 1.1 Create migration for `batch_status` PostgreSQL enum: `sealed`, `committed`, `verified`
- [x] 1.2 Create migration for `batches` table: bigint PK, chain_id FK, batch_number (integer), first_block (bigint), last_block (bigint), status (batch_status), commit_tx_hash (nullable string), verify_tx_hash (nullable string), timestamps. Unique index on `(chain_id, batch_number)`
- [x] 1.3 Create `Rexplorer.Schema.Batch` Ecto schema with chain association, changeset, and `@moduledoc`
- [x] 1.4 Verify migration runs: `mix ecto.migrate`

## 2. Ethrex Stack Module

- [x] 2.1 Create `Rexplorer.Chain.Ethrex` module with `__using__` macro that accepts config and overrides: `chain_id/0`, `chain_type/0` (`:zk_rollup`), `native_token/0` (`{"ETH", 18}`), `poll_interval_ms/0`, `bridge_contracts/0`, `block_fields/0` (`[{:batch_number, :integer}]`), `transaction_fields/0` (`[{:is_privileged, :boolean}, {:l1_origin_hash, :string}, {:fee_token, :string}]`)
- [x] 2.2 Add `@moduledoc` documenting how the Ethrex module works with dynamic module creation

## 3. Config-Driven Registry

- [x] 3.1 Add `ethrex_chains` config key to `config/config.exs` with an empty list default (and example commented out)
- [x] 3.2 Update `Rexplorer.Chain.Registry.init/1` to read `:ethrex_chains` config, dynamically create one adapter module per entry using `Module.create/3` with `use EVM` + `use Ethrex`, and register them in the adapter map alongside hardcoded adapters
- [x] 3.3 Auto-seed chain records: when creating Ethrex adapters, upsert the chain record in the `chains` table (chain_id, name, chain_type, native_token_symbol, explorer_slug) so no manual seeding is needed
- [x] 3.4 Write tests: Registry creates Ethrex adapter from config, `get_adapter` returns it, multiple Ethrex chains coexist, hardcoded adapters unaffected

## 4. RPC Client Extensions

- [x] 4.1 Add `Rexplorer.RPC.Client.ethrex_get_batch_by_block/2` — calls `ethrex_getBatchByBlock` with block number, returns batch info map or nil
- [x] 4.2 Add `Rexplorer.RPC.Client.ethrex_get_batch_by_number/2` — calls `ethrex_getBatchByNumber`, returns batch details including commit/verify hashes
- [x] 4.3 Add `Rexplorer.RPC.Client.ethrex_batch_number/1` — calls `ethrex_batchNumber`, returns latest batch number
- [x] 4.4 Write tests for Ethrex RPC methods with mock server

## 5. Indexer: Batch Fetching

- [x] 5.1 Update `RexplorerIndexer.Worker` to detect if the current chain is an Ethrex chain (check `adapter.chain_type() == :zk_rollup`)
- [x] 5.2 After block persistence on Ethrex chains, call `ethrex_getBatchByBlock` to get batch info. If returned: update block's `chain_extra` with `batch_number`, upsert batch record in `batches` table
- [x] 5.3 Add periodic batch status updater: every 30s on Ethrex chains, query `batches` where status != `verified`, call `ethrex_getBatchByNumber` to check for status transitions, update accordingly
- [x] 5.4 Handle RPC errors gracefully: if `ethrex_*` methods aren't available, skip batch tracking without crashing the worker

## 6. Indexer Config

- [x] 6.1 Add Ethrex chain RPC config to `config/config.exs` (under `:rexplorer_indexer, :chains`) — Ethrex chain entries should be auto-added from `ethrex_chains` config at supervisor startup
- [x] 6.2 Update `RexplorerIndexer.ChainSupervisor` to include Ethrex chains when building worker specs (read from the same `:rexplorer_indexer, :chains` map, which now includes Ethrex entries)

## 7. Tests

- [x] 7.1 Write tests for Ethrex adapter: verify all callback return values (chain_type, block_fields, transaction_fields, etc.)
- [x] 7.2 Write tests for Batch schema: insert, changeset validation, unique constraint
- [x] 7.3 Write test for dynamic adapter creation: config → module → registry lookup → correct values

## 8. Documentation

- [x] 8.1 Update `docs/chain-adapters.md` with Ethrex section: config-driven pattern, module hierarchy, how to add a new Ethrex deployment
- [x] 8.2 Create `docs/workflows/batch-lifecycle.md` with Mermaid sequence diagram showing: block indexed → batch fetched → batch status updated → committed → verified
- [x] 8.3 Update `docs/architecture.md` supported chains table and adapter diagram

## 9. Final Verification

- [x] 9.1 Run `mix test` — all tests pass
- [x] 9.2 Run `mix compile --warnings-as-errors`
- [x] 9.3 Verify with an Ethrex testnet if available (or verify startup + config parsing with mock RPC)
