# Block Indexing Workflow

## Overview

This workflow describes how a new block is fetched from a blockchain node, processed through the chain adapter, and persisted to the database. Each chain runs its own `RexplorerIndexer.Worker` GenServer with an independent poll loop.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Worker as Indexer Worker<br/>(GenServer)
    participant RPC as RPC.Client
    participant Node as Chain Node
    participant Proc as BlockProcessor
    participant Adapter as Chain Adapter
    participant Repo as Ecto Repo
    participant DB as PostgreSQL

    Worker->>Worker: handle_info(:poll)
    Worker->>RPC: get_latest_block_number(url)
    RPC->>Node: eth_blockNumber
    Node-->>RPC: "0x1312D00"
    RPC-->>Worker: {:ok, 20_000_000}

    alt New block available (target <= head)
        Worker->>RPC: get_block(url, target_block)
        RPC->>Node: eth_getBlockByNumber(hex, true)
        Node-->>RPC: block with full transactions
        RPC-->>Worker: {:ok, raw_block}

        Worker->>Worker: verify parentHash matches last indexed block
        alt Reorg detected (parentHash mismatch)
            Worker->>Worker: log warning and HALT (stop polling)
        end

        Worker->>RPC: get_block_receipts(url, target_block)
        RPC->>Node: eth_getBlockReceipts(hex)
        Node-->>RPC: all receipts for block
        RPC-->>Worker: {:ok, receipts}

        Worker->>Proc: process_block(raw_block, receipts, adapter)
        Proc->>Adapter: extract_operations(tx) per transaction
        Adapter-->>Proc: operations list
        Proc->>Adapter: extract_token_transfers(tx) per transaction
        Adapter-->>Proc: token transfers list
        Proc->>Proc: extract logs, discover addresses
        Proc-->>Worker: %{block, transactions, operations, logs, transfers, addresses}

        Worker->>Repo: Repo.transaction (atomic insert)
        Repo->>DB: INSERT block
        Repo->>DB: INSERT transactions (sequential)
        Repo->>DB: INSERT operations
        Repo->>DB: INSERT logs
        Repo->>DB: INSERT token_transfers
        Repo->>DB: INSERT addresses (on_conflict: nothing)
        DB-->>Repo: COMMIT
        Repo-->>Worker: {:ok, _}

        Worker->>Worker: update last_indexed_block + last_block_hash
        alt Still behind head
            Worker->>Worker: schedule :poll (0ms delay)
        else Caught up
            Worker->>Worker: schedule :poll (poll_interval_ms)
        end
    else No new block
        Worker->>Worker: schedule :poll (poll_interval_ms)
    end
```

## Components

| Component | Module | App | Responsibility |
|-----------|--------|-----|---------------|
| RPC Client | `Rexplorer.RPC.Client` | `rexplorer` | Stateless JSON-RPC HTTP wrapper |
| Worker | `RexplorerIndexer.Worker` | `rexplorer_indexer` | Per-chain GenServer poll loop |
| BlockProcessor | `RexplorerIndexer.BlockProcessor` | `rexplorer_indexer` | Pure RPC→Ecto transformation |
| Chain Adapter | `Rexplorer.Chain.Adapter` | `rexplorer` | Chain-specific extraction logic |
| Supervisor | `RexplorerIndexer.ChainSupervisor` | `rexplorer_indexer` | Starts/restarts workers |

## Error Handling

- **RPC failures:** Worker logs the error and retries on next poll cycle.
- **Duplicate blocks:** Unique constraint on `(chain_id, block_number)` prevents double-indexing. Worker detects and skips.
- **Chain reorganizations:** Detected via parentHash mismatch. Worker halts and requires manual intervention (v1). Auto-recovery planned for v2.
- **Worker crashes:** Supervisor restarts the worker. Worker bootstraps from DB on restart, resuming from last indexed block.

## Configuration

RPC endpoints are configured per-chain in `config/config.exs`:

```elixir
config :rexplorer_indexer,
  chains: %{
    1 => %{rpc_url: "http://localhost:8545"},
    10 => %{rpc_url: "http://localhost:9545"}
  }
```
