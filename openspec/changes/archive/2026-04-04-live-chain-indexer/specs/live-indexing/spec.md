## ADDED Requirements

### Requirement: Per-chain indexer worker
The system SHALL run one `RexplorerIndexer.Worker` GenServer per enabled chain. Each worker MUST maintain its state: `chain_id`, `last_indexed_block`, and the adapter module. On startup, the worker MUST bootstrap `last_indexed_block` by querying `MAX(block_number)` from the blocks table for its chain. If no blocks exist, it MUST start from the chain's current head block (via RPC).

#### Scenario: Worker starts with existing indexed data
- **WHEN** the worker for Ethereum starts and blocks up to 20,000,000 exist in the database
- **THEN** it sets `last_indexed_block` to 20,000,000 and begins polling for block 20,000,001

#### Scenario: Worker starts on fresh chain
- **WHEN** the worker for Ethereum starts and no blocks exist in the database
- **THEN** it queries the RPC node for the latest block number and begins indexing from that block

### Requirement: Polling loop
Each worker MUST run a poll loop using `Process.send_after(self(), :poll, interval)`. The poll interval MUST be determined by the chain adapter's `poll_interval_ms/0` callback. On each poll tick, the worker MUST:

1. Query the RPC node for the latest block number
2. If a new block is available (latest > last_indexed), fetch and process it
3. If still behind head after processing, schedule the next poll immediately (0ms delay)
4. If caught up, schedule the next poll after the adapter's poll interval

#### Scenario: New block available
- **WHEN** the poll tick fires and the RPC reports block N while last_indexed is N-1
- **THEN** the worker fetches block N, processes it, persists it, and updates last_indexed to N

#### Scenario: No new block yet
- **WHEN** the poll tick fires and the RPC reports the same block number as last_indexed
- **THEN** the worker does nothing and schedules the next poll after poll_interval_ms

#### Scenario: Multiple blocks behind
- **WHEN** the worker is 3 blocks behind head (e.g., last_indexed=100, head=103)
- **THEN** the worker processes block 101, then immediately polls again (0ms delay) to catch up

#### Scenario: Chain-specific poll interval
- **WHEN** the Ethereum adapter returns `poll_interval_ms() = 12_000` and Optimism returns `2_000`
- **THEN** the Ethereum worker polls every 12 seconds and the Optimism worker polls every 2 seconds when caught up

### Requirement: Reorg detection
Before persisting a new block, the worker MUST verify that the new block's `parentHash` matches the hash of the last indexed block. If it does not match, the worker MUST treat this as a chain reorganization.

#### Scenario: Normal block continuation
- **WHEN** block N+1 arrives with `parentHash` matching block N's hash in the database
- **THEN** the worker proceeds with normal indexing

#### Scenario: Reorg detected
- **WHEN** block N+1 arrives with `parentHash` that does NOT match block N's hash in the database
- **THEN** the worker MUST log a warning with the chain_id, block number, expected hash, and actual parentHash, and MUST stop polling (halt the worker)

### Requirement: Indexer supervisor
The system SHALL provide `RexplorerIndexer.Supervisor` that starts as part of the `rexplorer_indexer` application. On startup, it MUST query `Rexplorer.Chain.Registry.enabled_adapters/0` and start one `RexplorerIndexer.Worker` for each enabled chain. If a worker crashes, the supervisor MUST restart it with backoff.

#### Scenario: Application starts with enabled chains
- **WHEN** the rexplorer_indexer application starts and Ethereum and Optimism are enabled
- **THEN** two worker processes are started, one for each chain

#### Scenario: Worker crash and restart
- **WHEN** an indexer worker crashes due to an unhandled error
- **THEN** the supervisor restarts it after a backoff delay, and the worker resumes from its last indexed block (bootstrapped from DB)

### Requirement: Atomic block persistence
When persisting a block, the worker MUST insert all related data within a single database transaction: the block record, all transaction records, all operation records, all log records, all token transfer records, and any newly discovered address records. If any insert fails, the entire block MUST be rolled back.

#### Scenario: Successful block persistence
- **WHEN** block N is processed with 150 transactions, 400 logs, and 200 token transfers
- **THEN** all records are inserted in a single DB transaction and the block is committed

#### Scenario: Persistence failure rolls back
- **WHEN** a constraint violation occurs while inserting a transaction within block N
- **THEN** the entire block (including already-inserted transactions) is rolled back and the worker retries the block on the next poll

### Requirement: Duplicate block protection
The worker MUST handle the case where a block has already been indexed (e.g., after a restart). The unique constraint on `(chain_id, block_number)` in the database MUST prevent double-indexing. The worker MUST detect this and skip to the next block without error.

#### Scenario: Block already indexed
- **WHEN** the worker attempts to persist block N but it already exists in the database
- **THEN** the worker logs a debug message, updates last_indexed to N, and moves on
