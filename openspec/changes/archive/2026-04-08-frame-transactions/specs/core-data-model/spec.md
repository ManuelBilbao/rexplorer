## MODIFIED Requirements

### Requirement: Transaction storage with chain awareness
The system SHALL store transactions in a `transactions` table. Each transaction MUST be uniquely identified by `(chain_id, hash)`. Transactions MUST store: block reference, from_address, to_address (nullable — NULL for contract creation and frame transactions), value, input (calldata, nullable for frame transactions), gas_price, gas_used, nonce, transaction_type, status, transaction_index, a `chain_extra` JSONB column for chain-specific fields, and `payer` (nullable VARCHAR — the address that paid gas fees, set from receipt for frame transactions).

#### Scenario: Store standard EOA transfer
- **WHEN** a simple ETH transfer transaction is ingested
- **THEN** the system stores it with `from_address`, `to_address`, `value`, `transaction_type`, and `payer = NULL`

#### Scenario: Store frame transaction
- **WHEN** a type `0x06` frame transaction is ingested
- **THEN** the system stores it with `from_address = sender`, `to_address = NULL`, `value = 0`, `input = NULL`, `transaction_type = 6`, and `payer` set from the receipt

### Requirement: Event log storage
The system SHALL store event logs in a `logs` table. Each log MUST reference its parent transaction and store: log_index, contract_address, topic0 through topic3, data (raw bytes), a `decoded` JSONB column (nullable), and `frame_index` (nullable integer — set for logs from frame transactions to associate them with a specific frame).

#### Scenario: Store log from frame transaction
- **WHEN** a frame transaction's frame 2 emits an event
- **THEN** the log is stored with `frame_index = 2`

#### Scenario: Store log from regular transaction
- **WHEN** a regular transaction emits an event
- **THEN** the log is stored with `frame_index = NULL`

### Requirement: Operation abstraction
The system SHALL store operations in an `operations` table. An operation represents a single user intent extracted from a transaction. Each operation MUST reference its parent transaction and store: operation_type, operation_index, from_address, to_address, value, input data, decoded_summary, decoder_version, and `frame_index` (nullable integer — set for operations extracted from frame transaction frames).

#### Scenario: Operation from SENDER frame
- **WHEN** a SENDER frame is decoded into an operation
- **THEN** the operation is stored with `frame_index` set to the frame's index

#### Scenario: Operation from regular transaction
- **WHEN** a regular transaction produces an operation
- **THEN** the operation is stored with `frame_index = NULL`

### Requirement: Token transfer tracking
The system SHALL store token transfers in a `token_transfers` table. Each transfer MUST reference its parent transaction and store: from_address, to_address, token_contract_address, amount, token_type, token_id, and `frame_index` (nullable integer — set for transfers extracted from frame transaction frames).

#### Scenario: Token transfer from frame
- **WHEN** a SENDER frame emits a Transfer event
- **THEN** the token transfer is stored with `frame_index` set

#### Scenario: Token transfer from regular transaction
- **WHEN** a regular transaction includes a token transfer
- **THEN** the token transfer is stored with `frame_index = NULL`
