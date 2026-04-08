## 1. Database Schema

- [ ] 1.1 Create migration for `internal_transactions` table with columns: chain_id (FK), block_number, transaction_hash, transaction_index, trace_index, from_address, to_address, value (numeric), call_type (string), trace_address (integer[]), input_prefix (bytea), error (string). Unique index on (chain_id, block_number, transaction_index, trace_index). Indexes on (chain_id, from_address, block_number DESC) and (chain_id, to_address, block_number DESC)
- [ ] 1.2 Create `Rexplorer.Schema.InternalTransaction` Ecto schema with changeset
- [ ] 1.3 Document schema with `@moduledoc` including field descriptions

## 2. Trace Flattener Extension

- [ ] 2.1 Add `flatten_to_entries/1` to `RexplorerIndexer.TraceFlattener` — takes callTracer output, returns flat list of `%{from, to, value, call_type, trace_address, transaction_hash, transaction_index, trace_index, input_prefix, error}` maps. Filter: only value > 0 OR type in (CREATE, CREATE2, SELFDESTRUCT)
- [ ] 2.2 Assign `trace_address` (integer array path) and `trace_index` (sequential counter) during recursive walk
- [ ] 2.3 Extract `input_prefix` as first 4 bytes of input field (hex to binary)
- [ ] 2.4 Document `flatten_to_entries/1` with Mermaid diagram in module docs

## 3. Indexer Integration

- [ ] 3.1 Call `TraceFlattener.flatten_to_entries/1` in the worker alongside `flatten_traces/1`, using the same trace data (no extra RPC call)
- [ ] 3.2 Insert internal transactions in `persist_block/3` within the atomic transaction, using `Repo.insert_all` with `on_conflict: :nothing`
- [ ] 3.3 Document updated indexing pipeline with Mermaid sequence diagram

## 4. Domain Query Module

- [ ] 4.1 Create `Rexplorer.InternalTransactions` module with `list_by_address/3` — two separate queries on from_address and to_address indexes, merge/dedup/sort in Elixir, cursor-based pagination via `:before` (block_number) and `:limit`
- [ ] 4.2 Document the two-query union pattern in module docs

## 5. API Endpoints

- [ ] 5.1 Create `RexplorerWeb.Internal.InternalTransactionController` with `index/2` — serves `GET /internal/chains/:chain_slug/addresses/:address_hash/internal-transactions` with pagination
- [ ] 5.2 Add route in internal router
- [ ] 5.3 Create `RexplorerWeb.API.V1.InternalTransactionController` with `index/2` for public API
- [ ] 5.4 Add route in public API router
- [ ] 5.5 Document endpoints with `@moduledoc` and `@doc` annotations

## 6. Frontend

- [ ] 6.1 Add `InternalTransaction` type to `frontend/src/api/types.ts`
- [ ] 6.2 Add `useAddressInternalTransactions(chain, hash, before?)` React Query hook
- [ ] 6.3 Add "Internal Txns" tab to AddressPage with pagination — conditionally shown (only when data is available or chain supports traces)
- [ ] 6.4 Display internal tx entries: from → to, value, call type badge

## 7. Tests

- [ ] 7.1 Test `TraceFlattener.flatten_to_entries/1` — value filtering, trace_address paths, input_prefix extraction, empty traces
- [ ] 7.2 Test `Rexplorer.InternalTransactions.list_by_address/3` — from/to query, pagination, empty results
- [ ] 7.3 Test BFF internal transactions endpoint — success, pagination, empty
