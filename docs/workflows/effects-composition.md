# Effects Composition Workflow

## Overview

The "What Happened" section on the transaction detail page shows a human-readable timeline of on-chain effects. It is composed from two data sources: decoded event logs and raw token transfers.

## Data Flow

```mermaid
sequenceDiagram
    participant Indexer as Block Indexer
    participant BP as BlockProcessor
    participant DB as PostgreSQL
    participant DW as Decoder Worker
    participant ED as EventDecoder
    participant ABI as ABI Registry
    participant FE as Frontend

    Note over Indexer,DB: At indexing time
    Indexer->>BP: process_block(raw_block, receipts, adapter)
    BP->>BP: extract logs from receipts
    BP->>BP: extract token_transfers via adapter
    BP->>DB: INSERT logs (decoded = NULL)
    BP->>DB: INSERT token_transfers

    Note over DW,DB: At decode time (async)
    DW->>DB: SELECT logs WHERE decoded IS NULL
    DW->>ED: decode_log(log, token_cache)
    ED->>ABI: lookup_event(topic0)
    ABI-->>ED: event definition (name, types, indexed)

    alt Known event
        ED->>ED: decode indexed params from topics
        ED->>ED: decode data params from ABI
        ED->>ED: format_summary (with token resolution)
        ED-->>DW: %{event_name, params, summary}
        DW->>DB: UPDATE logs SET decoded = %{...}
    else Unknown event
        ED-->>DW: nil
        Note over DW: log.decoded stays NULL
    end

    Note over FE: At render time
    FE->>DB: GET /internal/tx/{hash} (BFF)
    DB-->>FE: {token_transfers, logs with decoded}

    FE->>FE: Filter logs where decoded != null
    FE->>FE: Check if decoded Transfer logs exist

    alt Decoded logs available
        FE->>FE: Render all decoded log summaries
        FE->>FE: linkifyAddresses() on each summary
    else No decoded logs (fallback)
        FE->>FE: Render raw token_transfers
        FE->>FE: Format native amounts with BigInt/18 decimals
    end

    FE->>FE: Display "What Happened" section
```

## Supported Event Types

| Event | Protocol | Summary Format |
|-------|----------|---------------|
| Transfer | ERC-20 | "Transfer 1,000 USDC from 0x7a25... to 0x3075..." |
| Approval | ERC-20 | "Approval: 0x7a25... approved 0x68b3... for Unlimited USDC" |
| Swap | Uniswap V2 | "Swap on pool 0x8ad5..." |
| Swap | Uniswap V3 | "Swap on pool 0x8ad5..." |
| Supply | Aave V3 | "Supply 1,000 USDC to Aave" |
| Withdraw | Aave V3 | "Withdraw 1,000 USDC from Aave" |
| Borrow | Aave V3 | "Borrow 500 USDC from Aave" |
| Repay | Aave V3 | "Repay 500 USDC to Aave" |
| Deposit | WETH | "WETH Deposit 1.0 ETH" |
| Withdrawal | WETH | "WETH Withdrawal 1.0 ETH" |

## Amount Formatting

- **Known tokens** (in token cache): raw amount divided by token's decimals
- **Unknown tokens** (not in cache): raw amount displayed as-is (no incorrect guessing)
- **Unlimited approvals** (amount ≥ 10^30): displayed as "Unlimited"
- **Native transfers** (frontend fallback): BigInt division by 10^18

## Deduplication

When decoded Transfer logs exist, the frontend shows the decoded summaries (which have proper token resolution and formatting). Raw token_transfers are only shown as a fallback when no decoded Transfer events are available — preventing duplicate display of the same transfer.
