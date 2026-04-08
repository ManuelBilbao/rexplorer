## ADDED Requirements

### Requirement: Frame transaction processing
The `BlockProcessor` SHALL detect transactions with `type == "0x6"` and extract frame data from the transaction's `frames` array and the receipt's `frameReceipts` array. For frame transactions, `to_address` SHALL be set to NULL, `value` to 0, and `input` to NULL. The `payer` field SHALL be read from `receipt["payer"]`.

#### Scenario: Frame transaction detected and processed
- **WHEN** a block contains a type `0x06` transaction with 3 frames
- **THEN** the BlockProcessor produces a transaction record (to=NULL, value=0) plus 3 frame records with mode, target, gas, status, and data

#### Scenario: Mixed block with frame and regular transactions
- **WHEN** a block contains both type `0x02` and type `0x06` transactions
- **THEN** regular transactions are processed with existing logic and frame transactions use the new frame extraction path

### Requirement: Per-frame operation extraction
For SENDER frames, the BlockProcessor SHALL call `extract_operations` with `from = tx.sender`, `to = frame.target`, `input = frame.data`, `logs = frame's logs`. For DEFAULT frames, it SHALL call with `from = entry_point (0x...aa)`. For VERIFY frames, no operations SHALL be extracted. Each extracted operation MUST include `frame_index`.

#### Scenario: SENDER frame decoded
- **WHEN** a SENDER frame targets a known contract with recognizable calldata
- **THEN** an operation is extracted with the frame's target as `to_address` and `frame_index` set

### Requirement: Per-frame log and token transfer extraction
For frame transactions, the BlockProcessor SHALL iterate `frameReceipts` and extract logs and token transfers per frame, setting `frame_index` on each. The aggregate `receipt.logs` SHALL NOT be used for frame transactions — only per-frame logs from `frameReceipts`.

#### Scenario: Logs extracted per frame
- **WHEN** a frame transaction has 3 frames, each emitting 2 logs
- **THEN** 6 log records are created, each with the correct `frame_index` (0, 0, 1, 1, 2, 2)
