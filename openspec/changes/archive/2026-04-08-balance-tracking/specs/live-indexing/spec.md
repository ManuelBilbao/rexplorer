## ADDED Requirements

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

### Diagram: Balance indexing data flow

```mermaid
sequenceDiagram
    participant W as Indexer Worker
    participant A as Chain Adapter
    participant RPC as RPC Node
    participant DB as Database

    W->>RPC: eth_getBlockByNumber(N)
    W->>RPC: eth_getBlockReceipts(N)
    W->>A: collect_touched_addresses(rpc_url, block, receipts)

    alt Adapter supports traces
        A->>RPC: debug_traceBlockByNumber(N, {callTracer})
        A-->>A: Flatten nested call trees
        A-->>W: MapSet of all touched addresses
    else No trace support
        A-->>W: MapSet from tx.from + tx.to + miner + withdrawals
    end

    loop Each touched address
        W->>RPC: eth_getBalance(addr, N)
        W->>DB: Lookup last known balance
        alt First time seen
            W->>RPC: eth_getBalance(addr, N-1)
            Note over W: Insert seed row
        end
        alt Balance changed
            Note over W: Queue balance_changes row + address update
        end
    end

    W->>DB: BEGIN TRANSACTION
    Note over W,DB: Persist block + txs + ops + logs + transfers + addresses + balance_changes
    W->>DB: COMMIT
```
