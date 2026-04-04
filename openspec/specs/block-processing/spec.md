## ADDED Requirements

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
For each transaction, the block processor MUST call the chain adapter's `extract_operations/1` callback to decompose the transaction into operations. The processor MUST set the `chain_id` and `transaction_id` references on each operation.

#### Scenario: EOA transfer produces single operation
- **WHEN** processing a simple ETH transfer through the Ethereum adapter
- **THEN** one operation of type `call` with `operation_index: 0` is produced

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
The block processor MUST collect all unique addresses encountered during processing: transaction `from_address`, `to_address`, log `contract_address`, and token transfer addresses. Each discovered address MUST be returned with its `chain_id` and `first_seen_at` set to the block timestamp. Addresses MUST be deduplicated within the block.

#### Scenario: Addresses collected from block
- **WHEN** a block with 3 transactions involving 5 unique addresses is processed
- **THEN** 5 address attribute maps are returned, each with `first_seen_at` set to the block's timestamp

#### Scenario: Duplicate addresses within block
- **WHEN** the same address appears in multiple transactions within a block
- **THEN** only one address attribute map is returned for that address
