# Indexer Startup Workflow

## Overview

This workflow describes how the indexer application boots up, discovers enabled chains, and starts per-chain worker processes that begin indexing.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant App as RexplorerIndexer.Application
    participant Sup as ChainSupervisor
    participant Reg as Chain.Registry
    participant Config as Application Config
    participant DB as PostgreSQL
    participant W1 as Worker (Ethereum)
    participant W2 as Worker (Optimism)
    participant RPC as RPC Node

    App->>Sup: start_link()
    Sup->>Config: read :rexplorer_indexer, :chains
    Config-->>Sup: %{1 => %{rpc_url: ...}, 10 => %{rpc_url: ...}}

    Sup->>Reg: enabled_adapters()
    Reg->>DB: SELECT chain_id FROM chains WHERE enabled = true
    DB-->>Reg: [1, 10]
    Reg-->>Sup: [Ethereum, Optimism]

    Sup->>Sup: filter adapters with configured RPC URLs

    par Start workers
        Sup->>W1: start_link(adapter: Ethereum, rpc_url: ...)
        Sup->>W2: start_link(adapter: Optimism, rpc_url: ...)
    end

    W1->>DB: SELECT MAX(block_number) FROM blocks WHERE chain_id = 1
    DB-->>W1: 20_000_000

    W1->>W1: last_indexed = 20_000_000, schedule :poll

    W2->>DB: SELECT MAX(block_number) FROM blocks WHERE chain_id = 10
    DB-->>W2: nil (no blocks yet)

    W2->>RPC: eth_blockNumber
    RPC-->>W2: current head

    W2->>W2: last_indexed = head - 1, schedule :poll

    Note over W1,W2: Workers now polling independently
```

## Step-by-Step

1. **Application Start** — `RexplorerIndexer.Application.start/2` starts `ChainSupervisor` as a child.

2. **Chain Discovery** — The supervisor reads the chain configuration (RPC URLs) and queries the registry for enabled adapters. Only chains with both an enabled DB record AND a configured RPC URL are started.

3. **Worker Start** — One `RexplorerIndexer.Worker` is started per chain, supervised with `:one_for_one` strategy.

4. **DB Bootstrap** — Each worker queries `MAX(block_number)` for its chain. If blocks exist, it resumes from there. If no blocks exist (fresh chain), it queries the RPC node for the current head and starts from there.

5. **First Poll** — Workers schedule their first `:poll` message with 0ms delay, beginning the indexing loop.

## Failure Scenarios

| Scenario | Behavior |
|----------|----------|
| DB unavailable at boot | Supervisor fails to start, application retries |
| RPC unavailable at boot | Worker starts but bootstrap uses block 0 as fallback, first poll will fail and retry |
| Worker crash during indexing | Supervisor restarts worker with backoff, worker re-bootstraps from DB |
| Chain disabled in DB | Worker not started for that chain |
| No RPC URL configured | Worker not started, warning logged |
