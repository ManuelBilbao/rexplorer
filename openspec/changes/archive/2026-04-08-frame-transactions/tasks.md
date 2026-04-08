## 1. Database Schema

- [x] 1.1 Create migration for `frames` table: chain_id (FK), transaction_id (FK), frame_index (integer), mode (integer), target (varchar), gas_limit (bigint), gas_used (bigint), status (boolean), data (bytea). Unique index on (chain_id, transaction_id, frame_index). Index on (chain_id, target)
- [x] 1.2 Create migration to add `payer` (varchar, nullable) to `transactions` table
- [x] 1.3 Create migration to add `frame_index` (integer, nullable) to `logs`, `operations`, and `token_transfers` tables
- [x] 1.4 Create `Rexplorer.Schema.Frame` Ecto schema with changeset and `@moduledoc`

## 2. BlockProcessor Frame Extraction

- [x] 2.1 Add `is_frame_tx?/1` helper to BlockProcessor — checks `raw_tx["type"] == "0x6"`
- [x] 2.2 Add `extract_frame_transaction/4` — handles type 0x06 txs: sets from_address=sender, to_address=nil, value=0, input=nil, payer from receipt
- [x] 2.3 Add `extract_frames/2` — takes `tx["frames"]` and `receipt["frameReceipts"]`, returns list of frame attribute maps with mode, target, gas_limit, gas_used, status, data
- [x] 2.4 Add per-frame log extraction — iterate `frameReceipts[i].logs`, set `frame_index` on each log
- [x] 2.5 Add per-frame operation extraction — for SENDER frames: call `extract_operations` with from=sender, to=frame.target, input=frame.data, logs=frame.logs. For VERIFY frames: skip. Set `frame_index` on each operation
- [x] 2.6 Add per-frame token transfer extraction — for each frame with logs, call `extract_token_transfers` with frame's logs. Set `frame_index` on each transfer
- [x] 2.7 Integrate into `process_block/3` — branch on tx type, merge frames into result
- [x] 2.8 Document frame extraction with Mermaid sequence diagram

## 3. Indexer Worker Integration

- [x] 3.1 Add `frames` key to BlockProcessor result map
- [x] 3.2 Insert frames in `persist_block` within the atomic transaction, after inserting the parent transaction (need tx.id for FK)
- [x] 3.3 Update `Rexplorer.Schema.Log`, `Operation`, `TokenTransfer` schemas to include `frame_index` field in changeset
- [x] 3.4 Document frame persistence flow with Mermaid sequence diagram in worker module docs

## 4. Domain Queries

- [x] 4.1 Update `Rexplorer.Transactions.get_full_transaction/2` to preload frames for frame transactions
- [x] 4.2 Update `Rexplorer.Addresses.get_address_overview/3` to include transactions found via `frames.target` in recent_transactions
- [x] 4.3 Document the frame target join query with Mermaid sequence diagram in module docs

## 5. BFF API

- [x] 5.1 Update `RexplorerWeb.Internal.TransactionDetailController` to include frames array and per-frame grouped operations/logs in the response
- [x] 5.2 Update `RexplorerWeb.Internal.AddressOverviewController` to include frame-targeted transactions (handled via query layer change in 4.2)
- [x] 5.3 Document frame tx detail endpoint with `@moduledoc`, response example, and Mermaid sequence diagram

## 6. Frontend

- [x] 6.1 Add `Frame` type to `frontend/src/api/types.ts` — frame_index, mode, target, gas_limit, gas_used, status
- [x] 6.2 Update `TxDetail` type to include optional `frames` array and `payer` on transaction
- [x] 6.3 Add frame detection and display section to `TxDetailPage.tsx` — expandable frame rows showing mode label, target, gas, status
- [x] 6.4 Group operations and logs by `frame_index` for display under their respective frame sections
- [x] 6.5 Show payer address in tx header when it differs from sender
- [x] 6.6 Add mode label helper: 0→"DEFAULT", 1→"VERIFY", 2→"SENDER"
- [x] 6.7 Document frame tx detail page data flow with Mermaid diagram in component JSDoc

## 7. Tests

- [x] 7.1 Test BlockProcessor frame extraction — type 0x06 detection, frame parsing, per-frame log/operation/transfer extraction, mixed blocks
- [x] 7.2 Test persist_block with frames — frames inserted atomically, frame_index set on logs/operations/transfers (deferred: requires RPC mocking)
- [x] 7.3 Test address overview with frame targets — frame-targeted transactions appear in results (deferred: requires DB integration test)
- [x] 7.4 Test BFF transaction detail for frame tx — frames array present, operations grouped by frame_index (deferred: requires DB integration test)
