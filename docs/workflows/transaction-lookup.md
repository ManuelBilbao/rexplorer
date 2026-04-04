# Transaction Lookup Workflow

## Overview

This workflow describes how a user's transaction hash query is resolved into a full transaction view, including operations (user intents), token transfers, event logs, and cross-chain links.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Web as RexplorerWeb
    participant Core as Rexplorer Core
    participant Repo as Ecto Repo
    participant DB as PostgreSQL

    User->>Web: GET /tx/{hash} or GET /{chain}/tx/{hash}
    Web->>Core: get_transaction(chain_id, hash)

    alt Chain specified in URL
        Core->>Repo: query transactions WHERE chain_id = X AND hash = Y
    else No chain specified
        Core->>Repo: query transactions WHERE hash = Y (any chain)
    end

    Repo->>DB: SELECT FROM transactions WHERE hash = $1
    DB-->>Repo: transaction row
    Repo-->>Core: transaction struct

    Core->>Repo: preload operations (ordered by operation_index)
    Repo->>DB: SELECT FROM operations WHERE transaction_id = $1
    DB-->>Repo: operation rows
    Repo-->>Core: operations with decoded_summary

    Core->>Repo: preload token_transfers
    Repo->>DB: SELECT FROM token_transfers WHERE transaction_id = $1
    DB-->>Repo: transfer rows

    Core->>Repo: preload logs
    Repo->>DB: SELECT FROM logs WHERE transaction_id = $1
    DB-->>Repo: log rows

    Core->>Repo: find cross-chain links
    Repo->>DB: SELECT FROM cross_chain_links WHERE source_tx_hash = $1 OR destination_tx_hash = $1
    DB-->>Repo: link rows (if any)

    Core->>Repo: resolve token metadata (join token_addresses + tokens)
    Repo->>DB: SELECT FROM token_addresses JOIN tokens
    DB-->>Repo: token names, symbols, decimals

    Core-->>Web: full transaction data

    Web->>Web: render response (JSON or HTML)
    alt Regular user view
        Web->>User: human-readable operation summaries, token names, cross-chain status
    else Advanced/dev view
        Web->>User: above + raw calldata, internal traces, log topics, storage diffs
    end
```

## Step-by-Step

1. **URL Routing** — the user provides a transaction hash, optionally scoped to a chain via URL prefix (e.g., `/optimism/tx/0xabc...`). If no chain is specified, the system searches across all chains.

2. **Transaction Lookup** — query the `transactions` table by `(chain_id, hash)` or just `hash`. Uses the unique index for fast lookups.

3. **Operation Loading** — preload all operations for the transaction, ordered by `operation_index`. Each operation may have a `decoded_summary` with the human-readable narration.

4. **Token Transfer Loading** — preload token transfers to show value movements (ERC-20, ERC-721, native transfers).

5. **Log Loading** — preload event logs. The `decoded` JSONB field may contain decoded event data from the decoder pipeline.

6. **Cross-Chain Link Resolution** — check if this transaction is part of a cross-chain journey (bridge deposit/withdrawal). If found, include the link status and the related transaction on the other chain.

7. **Token Metadata Resolution** — for token transfers, join through `token_addresses` to `tokens` to resolve human-readable names, symbols, and decimal places.

8. **Response Rendering** — the web layer renders the data with two levels of detail:
   - **Regular user view:** Human-readable operation summaries, token names/amounts, cross-chain status
   - **Advanced/dev view:** All of the above plus raw calldata, internal call traces, log topics, storage diffs

## Query Optimization

- Transaction lookup uses the `(chain_id, hash)` unique index — O(1) lookup
- Operations, transfers, and logs are loaded via foreign key index on `transaction_id`
- Cross-chain links use indexes on `source_tx_hash` and `destination_tx_hash`
- Token metadata can be cached (tokens table changes rarely)
