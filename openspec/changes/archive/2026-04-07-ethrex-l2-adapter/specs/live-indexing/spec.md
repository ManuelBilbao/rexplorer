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

#### Scenario: Batch committed on L1
- **WHEN** the updater checks batch 42 and `ethrex_getBatchByNumber` returns a `commit_tx_hash`
- **THEN** the batch status is updated from `sealed` to `committed` and the hash is stored

#### Scenario: Batch verified on L1
- **WHEN** the updater checks batch 42 and `ethrex_getBatchByNumber` returns a `verify_tx_hash`
- **THEN** the batch status is updated to `verified` and the hash is stored
