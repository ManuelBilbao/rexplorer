## Purpose

Pure transformation of raw RPC blocks and receipts into the attribute maps the indexer persists.

## Requirements

### Requirement: Raw block transformation
The system SHALL provide `RexplorerIndexer.BlockProcessor.process_block/3` that takes a raw RPC block map, a list of receipt maps, and a chain adapter module, and returns a structured result containing all Ecto-ready data for the block. This function MUST be pure (no side effects, no database calls).

#### Scenario: Process a standard block
- **WHEN** `process_block(raw_block, receipts, Rexplorer.Chain.Ethereum)` is called with a block containing 5 transactions
- **THEN** it returns a map with `:block`, `:transactions`, `:operations`, `:logs`, `:token_transfers`, and `:addresses` keys, each containing lists of attribute maps ready for Ecto insertion

### Requirement: Transaction processing
For each transaction in the raw block, the block processor MUST extract: hash, from_address, to_address, value, input (calldata), gas_price, nonce, transaction_type, and transaction_index. It MUST merge receipt data (status, gas_used) from the corresponding receipt (matched by transaction hash). All hex-encoded values MUST be decoded to their native types (integers, binaries). Addresses MUST be lowercased.

#### Scenario: Process transaction with receipt
- **WHEN** a transaction with hash `0xabc...` is processed alongside its receipt
- **THEN** the resulting transaction attrs include `status: true`, `gas_used: 21000` from the receipt, and `from_address` is lowercased

#### Scenario: Contract creation transaction
- **WHEN** a transaction has `to: null` (contract creation)
- **THEN** `to_address` is set to nil in the resulting attrs

### Requirement: Operation extraction via adapter
For each transaction, the block processor MUST call the chain adapter's `extract_operations/1` callback to decompose the transaction into operations. The processor MUST set the `chain_id` and `transaction_id` references on each operation. The transaction map passed to the adapter MUST include the transaction's event logs, which requires log extraction to run before operation extraction. Any `op_extra` returned on an operation MUST be preserved through to persistence.

#### Scenario: EOA transfer produces single operation
- **WHEN** processing a simple ETH transfer through the Ethereum adapter
- **THEN** one operation of type `call` with `operation_index: 0` is produced

#### Scenario: Logs available to operation extraction
- **WHEN** a transaction with event logs is processed
- **THEN** the transaction map handed to the adapter carries those logs

#### Scenario: Transaction with no receipt
- **WHEN** a transaction has no receipt and therefore no logs
- **THEN** operation extraction still runs, with an empty log list

#### Scenario: Structured extras preserved
- **WHEN** an unwrapper returns operations carrying `op_extra`
- **THEN** those values reach the database unchanged

### Requirement: Log extraction
For each receipt, the block processor MUST extract all event logs. Each log MUST include: log_index, contract_address (lowercased), topic0 through topic3, and raw data.

#### Scenario: Extract logs from receipt
- **WHEN** a receipt contains 3 event logs
- **THEN** 3 log attribute maps are produced with sequential log_index values and all topics populated

### Requirement: Token transfer extraction via adapter
For each transaction's logs, the block processor MUST call the chain adapter's `extract_token_transfers/1` callback to identify token transfer events. The adapter MUST handle standard ERC-20 `Transfer(address,address,uint256)` events at minimum.

#### Scenario: ERC-20 transfer detected
- **WHEN** a log with topic0 matching the Transfer event signature is processed through the Ethereum adapter
- **THEN** a token transfer with `token_type: :erc20`, decoded `from_address`, `to_address`, and `amount` is produced

#### Scenario: Native ETH transfer
- **WHEN** a transaction has a non-zero `value` field
- **THEN** the adapter produces a token transfer with `token_type: :native` and the transaction value as amount

### Requirement: Address discovery
The block processor MUST collect all unique addresses encountered during processing: transaction `from_address`, `to_address`, log `contract_address`, and token transfer addresses. Each discovered address MUST be returned with its `chain_id` and `first_seen_at` set to the block timestamp. Addresses MUST be deduplicated within the block. A discovered address MAY additionally carry a role label derived from how it was used in the block; where the same address is discovered with and without a label, the labelled form MUST win.

#### Scenario: Addresses collected from block
- **WHEN** a block with 3 transactions involving 5 unique addresses is processed
- **THEN** 5 address attribute maps are returned, each with `first_seen_at` set to the block's timestamp

#### Scenario: Duplicate addresses within block
- **WHEN** the same address appears in multiple transactions within a block
- **THEN** only one address attribute map is returned for that address

#### Scenario: Role label attached
- **WHEN** a block contains an AA bundle
- **THEN** the EntryPoint, paymaster, smart account senders and any account factory are returned as addresses carrying their role labels

#### Scenario: Labelled and unlabelled discovery of one address
- **WHEN** an address is discovered both as a plain transaction participant and in a labelled role within the same block
- **THEN** a single address map is returned, carrying the label

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

### Requirement: UserOperation persistence
Operations produced from a bundle MUST be persisted with the same guarantees as any other operation: within the block's atomic transaction, linked to the parent transaction, and with `operation_index` unique and sequential across the whole transaction regardless of how many UserOperations contributed. Address labels discovered during processing MUST be applied to address records that have no label yet, without disturbing records that already have one.

#### Scenario: Bundle persisted atomically
- **WHEN** a block containing a bundle is persisted
- **THEN** all of the bundle's operations are written in the same database transaction as the block, or none are

#### Scenario: Indexes are sequential across UserOperations
- **WHEN** a bundle with two UserOperations produces four operations in total
- **THEN** their `operation_index` values are 0, 1, 2, 3

#### Scenario: Label applied to a previously seen address
- **WHEN** an address already exists without a label and is discovered in a labelled role
- **THEN** the stored record gains the label

#### Scenario: Existing label not overwritten
- **WHEN** an address already carries a label and is discovered again
- **THEN** the stored label is left unchanged
