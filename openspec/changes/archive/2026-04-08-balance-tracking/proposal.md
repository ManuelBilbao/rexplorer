## Why

The address page currently shows metadata (is_contract, label, first_seen_at) and recent transactions, but has no balance information. Balance is the #1 thing users expect when looking up an address. Without it, Rexplorer cannot serve as a primary explorer. Beyond current balance, historical balance charts (like Trezor's portfolio view) give users insight into how an address's holdings evolved over time — a key differentiator over minimal explorers.

## What Changes

- Add a `balance_changes` table that records the absolute native-token balance at every block where an address's balance changed
- Extend the indexer to collect all touched addresses per block using `debug_traceBlockByNumber` with `callTracer` (capturing internal calls, CREATEs, and SELFDESTRUCTs) and fetch their balances via `eth_getBalance`
- For first-time addresses, seed the balance at the previous block (block N-1) to establish a baseline before indexing began
- Add `current_balance_wei` to the `addresses` table as a denormalized field for fast reads
- Expose balance data through the BFF API (current balance on address overview, historical balance for charts)
- Make trace-based address collection adapter-driven: full traces where supported (Ethrex), fallback to top-level tx addresses elsewhere

## Non-goals

- **Token (ERC-20/721/1155) balance tracking** — will be a separate change; this focuses on native token only
- **Backfill from genesis** — the seed-row approach handles the gap; full historical backfill is a future enhancement
- **Balance-based notifications or alerts** — out of scope
- **JSON-RPC batching optimization** — synchronous single calls are sufficient initially; batching can be layered on later
- **Daily rollup table** — not needed until chart query performance requires it

## Capabilities

### New Capabilities
- `balance-tracking`: Core balance change detection, storage, and querying — covers the `balance_changes` table, indexer integration for collecting touched addresses and fetching balances, seed-row logic for first-seen addresses, and query functions for current and historical balance
- `balance-api`: BFF and public API endpoints for address balance — current balance on address overview and historical balance series for charts

### Modified Capabilities
- `core-data-model`: Address tracking requirement gains `current_balance_wei` denormalized field
- `live-indexing`: Block indexing pipeline adds trace-based address collection and balance fetching step
- `domain-queries`: Address query module gains balance-related query functions
- `bff-api`: Address overview response includes balance data; new endpoint for balance history

## Impact

- **Database**: New `balance_changes` table; migration to add `current_balance_wei` to `addresses`
- **Indexer worker**: New step in `persist_block` flow — trace block, collect addresses, fetch balances, compare and store
- **RPC client**: New functions for `debug_traceBlockByNumber` and `eth_getBalance`
- **Chain adapters**: Must declare trace capability; adapter interface gains `trace_block` or similar
- **BFF API**: Address overview response changes (adds balance); new balance history endpoint
- **Public API**: Address endpoint response changes (adds balance)
- **Performance**: Each block now requires 1 trace call + N balance calls (N = unique touched addresses). Synchronous for now, targeting L2 block sizes
