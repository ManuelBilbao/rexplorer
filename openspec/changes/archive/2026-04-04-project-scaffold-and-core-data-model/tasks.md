## 1. Phoenix Umbrella Scaffold

- [x] 1.1 Generate Phoenix umbrella project `rexplorer_umbrella` with three child apps: `rexplorer` (core domain, `--no-web`), `rexplorer_indexer` (no web), `rexplorer_web` (Phoenix web layer)
- [x] 1.2 Configure shared Ecto Repo in the `rexplorer` core app with PostgreSQL adapter and per-environment database config (dev: `rexplorer_dev`, test: `rexplorer_test`)
- [x] 1.3 Set up inter-app dependencies: `rexplorer_web` and `rexplorer_indexer` depend on `rexplorer` core; `rexplorer` has no sibling dependencies
- [x] 1.4 Verify `mix compile`, `mix ecto.create`, and `mix test` pass from the umbrella root

## 2. Database Enums and Core Migrations

- [x] 2.1 Create migration for PostgreSQL enum types: `chain_type` (l1, optimistic_rollup, zk_rollup, sidechain), `operation_type` (call, user_operation, multisig_execution, multicall_item, delegate_call), `token_type` (native, erc20, erc721, erc1155), `cross_chain_link_type` (deposit, withdrawal, relay), `cross_chain_link_status` (initiated, relayed, proven, finalized)
- [x] 2.2 Create migration for `chains` table with chain_id PK, name, chain_type, native_token_symbol, explorer_slug, rpc_config (JSONB), enabled (boolean)
- [x] 2.3 Create migration for `blocks` table with bigint PK, chain_id FK, block_number, hash, parent_hash, timestamp, gas_used, gas_limit, base_fee_per_gas, chain_extra (JSONB). Unique index on (chain_id, block_number)
- [x] 2.4 Create migration for `transactions` table with bigint PK, chain_id FK, hash, block_id FK, from_address, to_address, value (numeric), input (binary), gas_price, gas_used, nonce, transaction_type, status, transaction_index, chain_extra (JSONB). Unique index on (chain_id, hash). Indexes on (chain_id, from_address) and (chain_id, to_address)
- [x] 2.5 Create migration for `operations` table with bigint PK, transaction_id FK, chain_id FK, operation_type (enum), operation_index, from_address, to_address, value (numeric), input (binary), decoded_summary (text nullable), decoder_version (integer nullable). Index on (transaction_id, operation_index)
- [x] 2.6 Create migration for `addresses` table with bigint PK, chain_id FK, hash, is_contract (boolean), contract_code_hash (nullable), label (nullable), first_seen_at (timestamp). Unique index on (chain_id, hash)
- [x] 2.7 Create migration for `tokens` table (bigint PK, name, symbol, decimals, logo_url nullable) and `token_addresses` table (bigint PK, token_id FK, chain_id FK, contract_address). Unique index on (chain_id, contract_address) for token_addresses
- [x] 2.8 Create migration for `token_transfers` table with bigint PK, transaction_id FK, chain_id FK, from_address, to_address, token_contract_address, amount (numeric), token_type (enum), token_id (nullable). Indexes on (chain_id, from_address) and (chain_id, to_address)
- [x] 2.9 Create migration for `logs` table with bigint PK, transaction_id FK, chain_id FK, log_index, contract_address, topic0-topic3, data (binary), decoded (JSONB nullable). Index on (chain_id, contract_address, topic0). Unique index on (chain_id, transaction_id, log_index)
- [x] 2.10 Create migration for `cross_chain_links` table with bigint PK, source_chain_id FK, source_tx_hash, destination_chain_id FK, destination_tx_hash (nullable), link_type (enum), message_hash, status (enum). Indexes on (source_chain_id, source_tx_hash) and (destination_chain_id, destination_tx_hash)
- [x] 2.11 Verify all migrations run cleanly: `mix ecto.reset` from umbrella root

## 3. Ecto Schemas

- [x] 3.1 Create `Rexplorer.Schema.Chain` with all fields, `chain_type` Ecto enum, and `@moduledoc`/`@doc` annotations
- [x] 3.2 Create `Rexplorer.Schema.Block` with chain association, all fields including `chain_extra`, and documentation
- [x] 3.3 Create `Rexplorer.Schema.Transaction` with block and chain associations, all fields, and documentation
- [x] 3.4 Create `Rexplorer.Schema.Operation` with transaction association, `operation_type` Ecto enum, `decoded_summary`, `decoder_version`, and documentation
- [x] 3.5 Create `Rexplorer.Schema.Address` with chain association, all fields, and documentation
- [x] 3.6 Create `Rexplorer.Schema.Token` and `Rexplorer.Schema.TokenAddress` with associations between them and to chains, and documentation
- [x] 3.7 Create `Rexplorer.Schema.TokenTransfer` with transaction and chain associations, `token_type` Ecto enum, and documentation
- [x] 3.8 Create `Rexplorer.Schema.Log` with transaction and chain associations, all fields, and documentation
- [x] 3.9 Create `Rexplorer.Schema.CrossChainLink` with chain and transaction associations, link_type/status enums, and documentation

## 4. Chain Adapter System

- [x] 4.1 Define `Rexplorer.Chain.Adapter` behaviour with `@callback` declarations and `@doc` for each: `chain_id/0`, `chain_type/0`, `native_token/0`, `block_fields/0`, `transaction_fields/0`, `extract_operations/1`, `bridge_contracts/0`
- [x] 4.2 Implement `Rexplorer.Chain.Ethereum` adapter module fulfilling all callbacks (chain_id: 1, chain_type: :l1, empty block/transaction fields, single `call` operation extraction, no bridge contracts)
- [x] 4.3 Implement `Rexplorer.Chain.Registry` GenServer with `get_adapter/1`, `list_adapters/0`, `enabled_adapters/0`. Load adapter config at startup from application env
- [x] 4.4 Add chain adapter configuration to `config/config.exs` registering Ethereum adapter
- [x] 4.5 Write tests for Registry (lookup by chain_id, unknown chain_id returns error, list/enabled filtering)
- [x] 4.6 Write tests for Ethereum adapter (callbacks return expected values, extract_operations produces single call operation)

## 5. Seed Data

- [x] 5.1 Create `priv/repo/seeds.exs` that inserts chain records for Ethereum (1), Optimism (10), Base (8453), BNB (56), and Polygon (137) with correct chain_types and native token symbols
- [x] 5.2 Verify `mix run priv/repo/seeds.exs` works and is idempotent (can run multiple times without duplicates)

## 6. Documentation

- [x] 6.1 Create `docs/architecture.md` with umbrella structure overview, app responsibilities, and Mermaid ER diagram of the full data model
- [x] 6.2 Create `docs/workflows/block-indexing.md` with Mermaid sequence diagram showing the flow: RPC Node → Indexer → Chain Adapter → Ecto → PostgreSQL (documenting the planned workflow even though indexing logic is not yet implemented)
- [x] 6.3 Create `docs/workflows/transaction-lookup.md` with Mermaid sequence diagram showing how a tx hash query flows through web → core → DB, including operation loading and cross-chain link resolution
- [x] 6.4 Create `docs/workflows/address-view.md` with Mermaid sequence diagram showing how address page data is assembled (transactions, token transfers, balances)
- [x] 6.5 Create `docs/chain-adapters.md` documenting the adapter behaviour contract, how to implement a new chain adapter, and the registry system — with a Mermaid class diagram

## 7. Final Verification

- [x] 7.1 Run full test suite from umbrella root: `mix test`
- [x] 7.2 Run `mix ecto.reset && mix run priv/repo/seeds.exs` to verify clean DB setup
- [x] 7.3 Verify all public modules have `@moduledoc` and all behaviour callbacks have `@doc`
