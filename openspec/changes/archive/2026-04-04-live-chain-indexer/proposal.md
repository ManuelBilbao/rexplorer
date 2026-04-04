## Why

The rexplorer database has schemas, migrations, and chain adapters — but no data. Without an indexer fetching blocks and transactions from blockchain nodes, the explorer has nothing to display. The live chain indexer is the data pipeline that keeps the database in sync with each chain's head, and is a prerequisite for every user-facing feature.

## What Changes

- **JSON-RPC client** (`Rexplorer.RPC.Client`) in the core app — a thin, stateless wrapper over HTTP for `eth_getBlockByNumber`, `eth_getBlockReceipts`, `eth_blockNumber`, and other standard Ethereum JSON-RPC methods
- **Indexer worker** (`RexplorerIndexer.Worker`) — a GenServer per chain that runs a poll loop: detect new blocks, fetch them, process them, persist them
- **Block processor** (`RexplorerIndexer.BlockProcessor`) — pure functions that transform raw RPC responses into Ecto-ready structs (blocks, transactions, operations, logs, token transfers, addresses)
- **Indexer supervisor** (`RexplorerIndexer.Supervisor`) — a DynamicSupervisor that starts one worker per enabled chain on application boot
- **New adapter callbacks** — `poll_interval_ms/0` (chain-specific polling frequency) and `extract_token_transfers/1` (chain-specific Transfer event parsing)
- **Reorg detection** — parent_hash verification on each new block; detect-and-halt behavior (log warning, stop indexing the affected chain) for v1

## Non-goals

- **Backfill / historical indexing** — no parallel block fetching, no catch-up-from-genesis mode. The indexer starts from the chain's current head (or a configured start block) and keeps up with new blocks
- **Automatic reorg recovery** — v1 detects reorgs but halts rather than auto-recovering. Manual intervention required
- **Decoder pipeline** — operations are extracted by the adapter but `decoded_summary` is not populated (that's a separate change)
- **Cross-chain link detection** — bridge event scanning is deferred to a follow-up change
- **WebSocket/subscription-based block notification** — polling only for v1

## Capabilities

### New Capabilities
- `rpc-client`: Stateless JSON-RPC client for communicating with Ethereum-compatible blockchain nodes
- `live-indexing`: Per-chain GenServer poll loop that fetches new blocks and persists them to the database
- `block-processing`: Pure transformation functions that convert raw RPC data into Ecto structs

### Modified Capabilities
- `chain-adapter`: Adding `poll_interval_ms/0` and `extract_token_transfers/1` callbacks; updating Ethereum reference implementation

## Impact

- **`apps/rexplorer/`** — new `Rexplorer.RPC.Client` module; updated `Rexplorer.Chain.Adapter` behaviour and `Rexplorer.Chain.Ethereum` implementation
- **`apps/rexplorer_indexer/`** — new modules: Worker, BlockProcessor, Supervisor; application.ex updated to start supervision tree
- **`config/`** — new RPC endpoint configuration per chain
- **Dependencies** — HTTP client library needed (Req or Finch)
- **Infrastructure** — requires running archive nodes with JSON-RPC endpoints for each chain

### Architectural fit
This is the first data pipeline in rexplorer. It exercises the full stack: chain adapters → RPC → processing → Ecto schemas → PostgreSQL. The GenServer-per-chain pattern establishes the per-chain isolation model that backfill, decoder pipeline, and other future indexing features will build on.
