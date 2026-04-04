# Address View Workflow

## Overview

This workflow describes how the address page assembles data from multiple tables to present a comprehensive view of an address: its metadata, transaction history, token transfers, and balances across chains.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Web as RexplorerWeb
    participant Core as Rexplorer Core
    participant Repo as Ecto Repo
    participant DB as PostgreSQL

    User->>Web: GET /{chain}/address/{hash}
    Web->>Core: get_address(chain_id, hash)

    Core->>Repo: query address metadata
    Repo->>DB: SELECT FROM addresses WHERE chain_id = $1 AND hash = $2
    DB-->>Repo: address row (is_contract, label, first_seen_at)
    Repo-->>Core: address struct

    par Parallel data loading
        Core->>Repo: recent transactions (paginated)
        Repo->>DB: SELECT FROM transactions WHERE chain_id = $1 AND (from_address = $2 OR to_address = $2) ORDER BY id DESC LIMIT 25
        DB-->>Repo: transaction rows
        Repo-->>Core: transactions

        Core->>Repo: recent token transfers (paginated)
        Repo->>DB: SELECT FROM token_transfers WHERE chain_id = $1 AND (from_address = $2 OR to_address = $2) ORDER BY id DESC LIMIT 25
        DB-->>Repo: transfer rows
        Repo-->>Core: token transfers

        Core->>Repo: resolve token metadata for transfers
        Repo->>DB: SELECT FROM token_addresses JOIN tokens WHERE chain_id = $1 AND contract_address IN ($3...)
        DB-->>Repo: token metadata
        Repo-->>Core: tokens with names/symbols/decimals
    end

    Core->>Core: assemble address view data

    Core-->>Web: address + transactions + transfers + tokens

    Web->>Web: render response
    alt Regular user view
        Web->>User: address label, transaction history with operation summaries, token balances
    else Advanced/dev view
        Web->>User: above + contract code, storage, internal transactions
    end
```

## Step-by-Step

1. **Address Lookup** — query the `addresses` table by `(chain_id, hash)` using the unique index. Returns metadata: is_contract flag, label (ENS/known name), first_seen_at timestamp.

2. **Parallel Data Loading** — to minimize latency, the following queries run in parallel:

   - **Recent Transactions:** paginated query on `transactions` table, matching on `from_address` or `to_address`. Uses the `(chain_id, from_address)` and `(chain_id, to_address)` indexes.

   - **Recent Token Transfers:** paginated query on `token_transfers` table with the same address matching pattern.

   - **Token Metadata:** for the token contract addresses found in transfers, resolve names, symbols, and decimals via `token_addresses` → `tokens` join.

3. **Data Assembly** — combine all loaded data into the address view struct.

4. **Response Rendering:**
   - **Regular user view:** Address label, paginated transaction list with human-readable operation summaries, token transfer history with resolved names and formatted amounts
   - **Advanced/dev view:** All of the above plus contract bytecode (if contract), storage state queries, internal transaction traces

## Pagination Strategy

- Cursor-based pagination using `id` (bigint) as the cursor — more efficient than OFFSET for large result sets
- Default page size: 25 items
- Separate cursors for transactions and token transfers (independent pagination)

## Cross-Chain Address View

When no chain is specified (e.g., `/address/{hash}`), the system can show the address across all chains where it appears:

```mermaid
sequenceDiagram
    participant User
    participant Web as RexplorerWeb
    participant Core as Rexplorer Core
    participant DB as PostgreSQL

    User->>Web: GET /address/{hash}
    Web->>Core: get_address_across_chains(hash)

    Core->>DB: SELECT FROM addresses WHERE hash = $1
    DB-->>Core: address rows (one per chain)

    loop For each chain where address exists
        Core->>DB: load recent activity (transactions + transfers)
        DB-->>Core: per-chain activity
    end

    Core-->>Web: multi-chain address view
    Web->>User: unified view with per-chain tabs
```

## Query Optimization

- Address lookups use the `(chain_id, hash)` unique index
- Transaction queries use `(chain_id, from_address)` and `(chain_id, to_address)` indexes
- Token transfer queries use the same index pattern
- Token metadata can be aggressively cached (changes are rare)
- Consider materialized views for address balance aggregations at scale
