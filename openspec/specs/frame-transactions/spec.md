## ADDED Requirements

### Requirement: Frames table
The system SHALL maintain a `frames` table storing per-frame data from EIP-8141 frame transactions. Each frame MUST be uniquely identified by `(chain_id, transaction_id, frame_index)` and MUST store: `mode` (integer: 0=DEFAULT, 1=VERIFY, 2=SENDER), `target` (address, nullable), `gas_limit`, `gas_used` (from frame receipt), `status` (boolean, from frame receipt), and `data` (bytea, full calldata). The table MUST have an index on `(chain_id, target)` for address page queries.

#### Scenario: Two-frame transaction stored
- **WHEN** a type `0x06` transaction with a VERIFY frame and a SENDER frame is indexed
- **THEN** two rows are inserted in the `frames` table with `frame_index` 0 and 1, each with their mode, target, gas, status, and data

#### Scenario: Frame receipt data stored
- **WHEN** the receipt contains `frameReceipts` with per-frame status and gas_used
- **THEN** each frame row's `gas_used` and `status` fields are populated from the corresponding frame receipt

### Requirement: Frame transaction detection
The system SHALL detect frame transactions by checking `transaction_type == 6`. When detected, the transaction MUST be stored with `to_address = NULL`, `value = 0`, `input = NULL`, and `payer` set from the receipt's `payer` field.

#### Scenario: Frame tx stored in transactions table
- **WHEN** a type `0x06` transaction is indexed
- **THEN** a transaction row is created with `from_address = tx.sender`, `to_address = NULL`, `value = 0`, `transaction_type = 6`, and `payer = receipt.payer`

#### Scenario: Regular tx unaffected
- **WHEN** a type `0x02` (EIP-1559) transaction is indexed
- **THEN** it is processed with existing logic, `payer` is NULL, and no frames are created

### Requirement: Per-frame log association
For frame transactions, each log MUST be associated with its source frame via `frame_index`. The system SHALL parse `frameReceipts[i].logs` and set `frame_index = i` on each log.

#### Scenario: Logs from different frames
- **WHEN** frame 2 emits a Transfer event and frame 3 emits a Swap event
- **THEN** the Transfer log has `frame_index = 2` and the Swap log has `frame_index = 3`

#### Scenario: Non-frame tx logs unchanged
- **WHEN** a regular transaction emits logs
- **THEN** the logs have `frame_index = NULL`

### Requirement: Per-frame operation extraction
SENDER frames SHALL be decoded as operations through the existing decoder pipeline, treating each as a mini-transaction with `from = tx.sender`, `to = frame.target`, `input = frame.data`, `logs = frame's logs`. DEFAULT frames SHALL optionally be decoded. VERIFY frames SHALL be skipped (not decoded). Each operation MUST store `frame_index` to link back to its source frame.

#### Scenario: SENDER frame produces decoded operation
- **WHEN** a SENDER frame calls a Uniswap contract
- **THEN** an operation is created with `frame_index` set, and the decoder pipeline produces `decoded_summary = "Swapped 100 USDC for 0.05 ETH"`

#### Scenario: VERIFY frame skipped
- **WHEN** a VERIFY frame is processed
- **THEN** no operation is created for it

### Requirement: Per-frame token transfer extraction
Token transfers extracted from frame transaction logs MUST include `frame_index` to associate them with their source frame.

#### Scenario: Token transfer from SENDER frame
- **WHEN** a SENDER frame emits a Transfer event for 100 USDC
- **THEN** a token_transfer row is created with `frame_index` set to the frame's index

### Requirement: Address page frame target query
The address page transaction query SHALL additionally search `frames.target` to find frame transactions where the address is a target of any frame. This ensures addresses that only interact via frame targets appear in transaction lists.

#### Scenario: Address found via frame target
- **WHEN** a user views the address page for 0xUniswap and a frame tx has a SENDER frame targeting 0xUniswap
- **THEN** that frame transaction appears in the address's transaction list
