## Why

Rexplorer supports Ethereum, OP Stack chains, and sidechains — but not Ethrex, Lambda's own ZK rollup stack. Ethrex deployments have unique features: custom transaction types (privileged deposits at 0x7E, fee-token transactions at 0x7D), a batch-based proving lifecycle (sealed → committed → verified), and config-driven deployments where each chain has its own chain ID, bridge address, and RPC URL. Adding Ethrex support makes rexplorer the native explorer for any Ethrex L2 deployment.

## What Changes

- **`Rexplorer.Chain.Ethrex` stack module** — defines Ethrex-specific transaction fields (`is_privileged`, `l1_origin_hash`, `fee_token`), block chain_extra fields (`batch_number`), and chain_type `:zk_rollup`. Similar to how OPStack works for Optimism/Base, but config-driven rather than one-module-per-chain.
- **Config-driven adapter instantiation** — Ethrex chains are defined entirely in config (`chain_id`, `name`, `bridge_address`, `rpc_url`, `poll_interval_ms`). The Registry dynamically creates adapter instances at startup without requiring a new Elixir module per deployment.
- **`batches` table** — new schema for batch lifecycle tracking: `batch_number`, `chain_id`, `first_block`, `last_block`, `status` (sealed/committed/verified), `commit_tx_hash`, `verify_tx_hash`. Blocks also store `batch_number` in `chain_extra` for O(1) block→batch lookup.
- **Batch data fetching** — the indexer worker calls `ethrex_getBatchByBlock` after persisting each block to populate batch info. A periodic batch status updater checks for status transitions (committed → verified) via `ethrex_getBatchByNumber`.
- **RPC client extensions** — new methods for Ethrex custom RPCs: `ethrex_batchNumber`, `ethrex_getBatchByNumber`, `ethrex_getBatchByBlock`.

## Non-goals

- Batch detail page in the frontend (deferred — just the data layer for now)
- Withdrawal proof status / merkle proof display
- L2-to-L2 cross-chain messaging
- Fee breakdown display (base + operator + L1 data)
- Forced inclusion tracking

## Capabilities

### New Capabilities
- `ethrex-adapter`: Config-driven Ethrex stack module with ZK rollup-specific fields and dynamic adapter instantiation
- `batch-tracking`: Batches table, migration, schema, and batch status fetching for Ethrex chains

### Modified Capabilities
- `chain-adapter`: Registry updated to support config-driven stack adapters alongside hardcoded modules
- `live-indexing`: Worker extended to fetch batch info for Ethrex chains after block persistence

## Impact

- **`apps/rexplorer/`** — new `Rexplorer.Chain.Ethrex` module, new `Rexplorer.Schema.Batch`, new migration for batches table, extended RPC client, updated Registry
- **`apps/rexplorer_indexer/`** — worker extended with batch fetching for Ethrex chains
- **`config/`** — new `ethrex_chains` configuration section
- **Database** — new `batches` table, new DB enum value `zk_rollup` already exists in `chain_type`
- **Seeds** — no changes (Ethrex chains are added purely via config)

### Architectural fit
This extends the chain adapter system with a new pattern: config-driven stack adapters. Hardcoded adapters (Ethereum, BNB, Polygon) and stack-specific modules (OPStack, Ethrex) coexist in the Registry. The batches table is the first L2 lifecycle entity — it lays the groundwork for the batch detail page and L2 finality tracking that was part of the original vision.
