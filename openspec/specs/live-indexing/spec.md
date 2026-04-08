## ADDED Requirements

### Requirement: Batch info fetching for Ethrex chains
After persisting a block on an Ethrex chain, the indexer worker SHALL call `ethrex_getBatchByBlock` to determine which batch the block belongs to. If batch info is returned:
1. Store `batch_number` in the block's `chain_extra`
2. Upsert a record in the `batches` table with the batch's block range and current status

#### Scenario: Block indexed with batch info
- **WHEN** block 1000 is persisted on an Ethrex chain and `ethrex_getBatchByBlock` returns batch 42 (blocks 990-1010)
- **THEN** block 1000's `chain_extra` is updated with `batch_number: 42` and the batches table has a record for batch 42

#### Scenario: Block not yet batched
- **WHEN** a block is persisted but `ethrex_getBatchByBlock` returns null (block not in a batch yet)
- **THEN** `chain_extra.batch_number` is null and no batch record is created

### Requirement: Batch status updater
The worker SHALL periodically check for batch status transitions on Ethrex chains. For batches in `sealed` or `committed` status, it SHALL call `ethrex_getBatchByNumber` to check if the batch has been committed or verified, and update the status and L1 tx hashes accordingly.

### Requirement: Balance collection during block indexing
After processing a block and before persisting, the indexer worker SHALL collect all touched addresses, fetch their balances, and include balance changes in the atomic database transaction. This step runs synchronously within the block indexing pipeline.

#### Scenario: Block indexed with balance changes
- **WHEN** block N is indexed on a chain with trace support and 3 addresses have balance changes
- **THEN** 3 `balance_changes` rows are inserted in the same DB transaction as the block, transactions, and other data

#### Scenario: Block indexed without any balance changes
- **WHEN** block N is indexed and all touched addresses have the same balance as their last known balance
- **THEN** no `balance_changes` rows are inserted and indexing proceeds normally

#### Scenario: Balance fetch failure does not block indexing
- **WHEN** `eth_getBalance` fails for one address during block N indexing
- **THEN** that address is skipped for balance tracking, a warning is logged, and the rest of the block is persisted normally

### Requirement: Trace-based address collection in indexer
The indexer worker SHALL call the adapter's `collect_touched_addresses` function to determine which addresses to check for balance changes. On chains with trace support, this involves an additional `debug_traceBlockByNumber` RPC call per block.

#### Scenario: Ethrex chain with traces
- **WHEN** a block is being indexed on an Ethrex chain
- **THEN** the worker calls `debug_traceBlockByNumber(N, {"tracer": "callTracer"})` and flattens the result to get all touched addresses

#### Scenario: Chain without trace support
- **WHEN** a block is being indexed on a chain without trace support
- **THEN** the worker extracts addresses from top-level transaction from/to fields, the block miner, and withdrawals only

#### Scenario: Batch committed on L1
- **WHEN** the updater checks batch 42 and `ethrex_getBatchByNumber` returns a `commit_tx_hash`
- **THEN** the batch status is updated from `sealed` to `committed` and the hash is stored

#### Scenario: Batch verified on L1
- **WHEN** the updater checks batch 42 and `ethrex_getBatchByNumber` returns a `verify_tx_hash`
- **THEN** the batch status is updated to `verified` and the hash is stored

### Requirement: Internal transaction persistence during block indexing
On chains with trace support, the indexer worker SHALL persist internal transactions from the trace data within the same atomic database transaction as blocks, transactions, and balance changes.

#### Scenario: Block with internal transactions
- **WHEN** block N is indexed on a chain with trace support and the trace contains 5 value-transferring internal calls
- **THEN** 5 `internal_transactions` rows are inserted in the same DB transaction

#### Scenario: Chain without trace support
- **WHEN** block N is indexed on a chain without trace support
- **THEN** no internal transactions are persisted and no trace RPC call is made
