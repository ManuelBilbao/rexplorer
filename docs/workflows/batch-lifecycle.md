# Batch Lifecycle Workflow

## Overview

Ethrex ZK rollup chains group blocks into batches that go through a commit/verify lifecycle on L1. The indexer tracks batch info alongside block indexing.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Worker as Indexer Worker
    participant RPC as Ethrex Node
    participant DB as PostgreSQL

    Note over Worker,DB: After persisting a block on an Ethrex chain

    Worker->>RPC: ethrex_getBatchByBlock(block_number)
    RPC-->>Worker: {batch_number, first_block, last_block, commit_tx, verify_tx}

    alt Batch info returned
        Worker->>DB: UPDATE blocks SET chain_extra.batch_number = 42
        Worker->>DB: UPSERT batches (chain_id, batch_number, first_block, last_block, status)

        alt verify_tx present
            Worker->>DB: SET status = verified, verify_tx_hash = ...
        else commit_tx present
            Worker->>DB: SET status = committed, commit_tx_hash = ...
        else Neither
            Worker->>DB: SET status = sealed
        end
    else No batch yet (null)
        Note over Worker: Block not yet batched, skip
    end

    Note over Worker,DB: Periodic batch status update (every 30s)

    Worker->>DB: SELECT batches WHERE status != verified AND chain is ethrex
    loop For each unsealed/uncommitted batch
        Worker->>RPC: ethrex_getBatchByNumber(batch_number)
        RPC-->>Worker: {commit_tx, verify_tx, ...}
        Worker->>DB: UPDATE batch status if progressed
    end
```

## Batch States

```
┌────────┐    commitBatch()    ┌───────────┐    verifyBatches()    ┌──────────┐
│ Sealed │ ──────────────────▶ │ Committed │ ────────────────────▶ │ Verified │
└────────┘                     └───────────┘                       └──────────┘
  Blocks                        commit_tx_hash                      verify_tx_hash
  grouped                       set (L1 tx)                         set (L1 tx)
  locally                                                           ZK proof valid
```

## Data Model

```
batches table:
  chain_id      → FK to chains
  batch_number  → unique per chain
  first_block   → first L2 block in batch
  last_block    → last L2 block in batch
  status        → sealed | committed | verified
  commit_tx_hash → L1 tx that committed the batch
  verify_tx_hash → L1 tx that verified the ZK proof

blocks.chain_extra:
  batch_number  → denormalized for O(1) block→batch lookup
```

## Lookup Patterns

| Query | Method |
|-------|--------|
| Block → batch | Read `block.chain_extra.batch_number` (O(1)) |
| Batch → blocks | Query batches table for `first_block`/`last_block` range |
| Batch lifecycle | Query batches table by `(chain_id, batch_number)` |
| Unverified batches | Query `WHERE status != 'verified'` for status updates |
