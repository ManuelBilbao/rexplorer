## Why

EIP-8141 introduces Frame Transactions (type `0x06`) — a new transaction format where a single transaction contains multiple sequential execution steps called "frames." Each frame has its own mode (VERIFY, SENDER, DEFAULT), target address, gas limit, calldata, and produces its own status, gas usage, and logs. This is the protocol-native account abstraction mechanism, decoupling transaction validation from ECDSA and enabling paymasters, batched operations, and alternative signature schemes at the protocol level.

Ethrex already implements EIP-8141 and produces frame transactions on its demo network. The current Rexplorer indexer and UI cannot handle them — `extract_transaction` expects `to`, `value`, and `input` fields that don't exist on frame txs, and the receipt parsing assumes a single status and flat log list.

Frame transactions are a general EVM feature (not Ethrex-specific) — any chain could adopt EIP-8141 in the future.

## What Changes

- Add a `frames` table storing per-frame data (mode, target, gas_limit, gas_used, status, data) linked to the parent transaction
- Add `payer` field to `transactions` table (from frame tx receipts — the address that paid gas, may differ from sender for sponsored txs)
- Add `frame_index` to `logs`, `operations`, and `token_transfers` tables to associate them with specific frames
- Extend `BlockProcessor` to detect type `0x06` transactions and extract frames + per-frame receipts
- Decode SENDER frames as operations through the existing decoder pipeline (ABI decode → unwrap → interpret → narrate)
- Skip operation extraction for VERIFY frames (signature data, not user intent)
- Display frames on the tx detail page as expandable sections with per-frame status, gas, decoded operations, and logs
- Query frames by target address for the address page — so frame tx targets appear in transaction lists (similar to how internal transactions solved deposit visibility)

## Non-goals

- **VERIFY scheme detection** — detecting whether secp256k1 or P256 was used (available from `data[0]` but deferred)
- **Smart account verification decoding** — custom VERIFY logic in contract accounts
- **Frame-level trace visualization** — nested call trees within individual frames
- **Blob data handling** — `blobVersionedHashes` from frame txs
- **Mempool/pending frame tx display** — only indexed (confirmed) frame txs

## Capabilities

### New Capabilities
- `frame-transactions`: Storage, indexing, querying, and display of EIP-8141 frame transaction data including per-frame receipts, operations, logs, and address page integration

### Modified Capabilities
- `core-data-model`: Transactions gain `payer` field; logs, operations, and token_transfers gain `frame_index`
- `live-indexing`: BlockProcessor handles type `0x06` tx parsing and frame receipt extraction
- `block-processing`: Frame extraction and per-frame operation/token-transfer derivation
- `domain-queries`: Transaction and address queries include frame data
- `bff-api`: Transaction detail response includes frames; address queries include frame-based transactions
- `frontend-pages`: Tx detail page shows frames; address page finds txs via frame targets

## Impact

- **Database**: New `frames` table; migrations to add `payer` to transactions, `frame_index` to logs/operations/token_transfers
- **BlockProcessor**: Type `0x06` detection, frame extraction, per-frame receipt parsing, per-frame operation and token transfer extraction
- **RPC client**: No changes — frame data comes in standard `eth_getBlockByNumber` and `eth_getBlockReceipts` responses
- **Indexer worker**: No changes — BlockProcessor produces the frame data, persist_block inserts it
- **BFF/API**: Transaction detail response includes frames array; address queries join on frames.target
- **Frontend**: Tx detail page gains frame display; address page query includes frame targets
- **Chain adapter**: No changes — frame txs are detected by type, not adapter
