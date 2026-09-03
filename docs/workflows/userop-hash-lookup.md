# UserOp Hash Lookup Workflow

## Overview

A user who sent a transaction through a smart wallet has a **userOpHash**, not
a transaction hash — that is what their wallet showed them. Pasting it into the
search bar must land them on the transaction it was bundled into.

The lookup is a fallback on the transaction-hash path: both are 66-character
hex strings, and transaction hashes are the overwhelmingly common case, so they
must not pay for the fallback.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant UI as SearchBar
    participant BFF as SearchController
    participant Search as Rexplorer.Search
    participant DB as PostgreSQL

    User->>UI: paste 0xab… (66 hex chars)
    UI->>BFF: GET /internal/search?q=0xab…
    BFF->>Search: query(input, chain_id: …)

    Search->>Search: classify — 66 hex → transaction hash
    Search->>DB: SELECT transactions WHERE hash = $1

    alt A transaction matches
        DB-->>Search: transaction
        Search-->>BFF: {type: :transaction, results: [tx]}
    else No transaction
        DB-->>Search: []
        Note over Search,DB: fallback — the hash may be a userOpHash
        Search->>DB: SELECT operations JOIN transactions<br/>WHERE op_extra ? 'user_op_hash'<br/>AND op_extra->>'user_op_hash' = $1
        Note over DB: the existence predicate is what lets<br/>Postgres use the partial index
        DB-->>Search: operations with parent transaction
        Search-->>BFF: {type: :user_operation, results: [...]}
    end

    BFF->>BFF: format results, build redirect
    BFF-->>UI: {type, results, redirect: "/ethereum/tx/0x…"}
    UI->>User: navigate to the transaction page
```

## The index

```sql
CREATE INDEX operations_user_op_hash_idx
  ON operations (chain_id, (op_extra->>'user_op_hash'))
  WHERE op_extra ? 'user_op_hash';
```

Partial, because ERC-4337 operations are a small fraction of all operations.
The partial predicate is only usable when the query carries it, which is why
`Rexplorer.Search` includes `op_extra ? 'user_op_hash'` alongside the equality
— without it the planner falls back to a scan.

## Notes

- A batched UserOperation produces several operations sharing one hash. They
  all live in the same transaction, so the redirect is the same for each.
- Scoping to a chain adds `chain_id` to the query, matching the index's leading
  column.
- A hash matching neither a transaction nor a userOpHash returns an empty
  result, exactly as before this fallback existed.
