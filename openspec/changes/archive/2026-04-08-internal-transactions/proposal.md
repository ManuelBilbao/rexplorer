## Why

On Ethrex L2, deposit transactions have `from: 0x...ffff` and `to: 0x...ffff` (system/bridge addresses). The actual recipient only appears in the internal call trace. Without storing internal transactions, deposit recipients have no transactions on their address page — the query `WHERE from_address = ? OR to_address = ?` finds zero matches. This is the most common user journey on an L2 explorer (check if my deposit arrived), and it's broken.

Beyond deposits, internal transactions cover contract-to-contract ETH transfers, CREATE/CREATE2 deployments, and SELFDESTRUCTs — all invisible at the top-level transaction layer. Every major explorer (Etherscan, Blockscout) stores these as a separate entity with a dedicated address page tab.

## What Changes

- Add an `internal_transactions` table storing value-transferring trace entries (CALL with value > 0, CREATE, SELFDESTRUCT). Zero-value calls and staticcalls/delegatecalls are excluded to keep storage lean.
- Extend the indexer to persist internal transactions from the trace data already being collected by `TraceFlattener` during balance tracking
- Add query functions for internal transactions by address with cursor-based pagination
- Add BFF and public API endpoints for address internal transactions
- Add "Internal Txns" tab to the frontend address page

## Non-goals

- **Full trace storage** — we only store value-transferring entries, not every call/staticcall/delegatecall
- **Input/output data** — only store the first 4 bytes of input (function selector) to save space; full calldata is available via RPC on demand
- **Trace visualization** — nested call tree rendering on the tx detail page is a future enhancement
- **Non-Ethrex L2 deposit linking** — OP Stack deposits use a different mechanism (deposit tx type); this change focuses on the general internal transactions model

## Capabilities

### New Capabilities
- `internal-transactions`: Storage, indexing, querying, and API for internal transactions derived from block traces

### Modified Capabilities
- `live-indexing`: Block indexing pipeline adds internal transaction persistence from existing trace data
- `domain-queries`: New query module for internal transactions by address
- `bff-api`: New endpoint for address internal transactions
- `frontend-pages`: Address page gains "Internal Txns" tab

## Impact

- **Database**: New `internal_transactions` table with indexes on `(chain_id, from_address)` and `(chain_id, to_address)`
- **Indexer**: `TraceFlattener` extended to return structured trace entries (not just addresses). `persist_block` inserts internal transactions in the same atomic transaction
- **RPC client**: No changes — `debug_traceBlockByNumber` data is already fetched
- **BFF/API**: New endpoints for paginated internal transactions by address
- **Frontend**: New tab on address page, new React Query hook, new type definition
- **Adapter pattern**: Only chains with `supports_traces? == true` produce internal transactions
