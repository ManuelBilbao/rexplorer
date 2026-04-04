## ADDED Requirements

### Requirement: Multi-chain block storage
The system SHALL store blocks from multiple chains in a single `blocks` table. Each block MUST be uniquely identified by `(chain_id, block_number)`. Blocks MUST store: hash, parent_hash, timestamp, gas_used, gas_limit, base_fee_per_gas, and a `chain_extra` JSONB column for chain-specific fields (e.g., L2 batch index, blob gas used).

#### Scenario: Store Ethereum mainnet block
- **WHEN** a block is ingested from Ethereum mainnet
- **THEN** the system stores it with `chain_id` referencing the Ethereum chain and all standard fields populated

#### Scenario: Store Optimism block with L2-specific data
- **WHEN** a block is ingested from Optimism
- **THEN** the system stores it with standard fields AND the `chain_extra` JSONB column containing L2-specific fields (e.g., `l1_block_number`, `sequence_number`)

#### Scenario: Reject duplicate blocks
- **WHEN** a block with the same `(chain_id, block_number)` already exists
- **THEN** the system SHALL enforce uniqueness and reject the duplicate

### Requirement: Transaction storage with chain awareness
The system SHALL store transactions in a `transactions` table. Each transaction MUST be uniquely identified by `(chain_id, hash)`. Transactions MUST store: block reference, from_address, to_address, value, input (calldata), gas_price, gas_used, nonce, transaction_type, status, transaction_index, and a `chain_extra` JSONB column for chain-specific fields.

#### Scenario: Store standard EOA transfer
- **WHEN** a simple ETH transfer transaction is ingested
- **THEN** the system stores it with `from_address`, `to_address`, `value`, and `transaction_type` set to the appropriate EIP-2718 type

#### Scenario: Store L2 transaction with deposit metadata
- **WHEN** a deposit transaction from L1→L2 is ingested on an L2 chain
- **THEN** the `chain_extra` JSONB column SHALL contain the L1 origin transaction hash and deposit nonce

### Requirement: Operation abstraction
The system SHALL store operations in an `operations` table. An operation represents a single user intent extracted from a transaction. A transaction MAY contain one or more operations. Each operation MUST reference its parent transaction and store: operation_type (enum: `call`, `user_operation`, `multisig_execution`, `multicall_item`, `delegate_call`), operation_index within the transaction, from_address (the logical sender), to_address, value, input data, and decoded_summary (nullable text for the human-readable narration).

#### Scenario: Simple EOA transaction produces one operation
- **WHEN** a standard EOA-to-EOA transfer is processed
- **THEN** exactly one operation with type `call` is created, referencing the transaction

#### Scenario: AA bundler transaction produces multiple operations
- **WHEN** an ERC-4337 `handleOps` bundler transaction is processed
- **THEN** one operation of type `user_operation` is created for each UserOperation in the bundle, each with its own logical `from_address` (the smart wallet sender)

#### Scenario: Safe multisig execution produces wrapped operation
- **WHEN** a Safe `execTransaction` call is processed
- **THEN** one operation of type `multisig_execution` is created, with `from_address` set to the Safe address and the inner call data stored in `input`

#### Scenario: Multicall produces multiple operations
- **WHEN** a `multicall()` transaction is processed
- **THEN** one operation of type `multicall_item` is created per inner call, ordered by `operation_index`

### Requirement: Address tracking
The system SHALL maintain an `addresses` table. Each address MUST be uniquely identified by `(chain_id, hash)`. Addresses MUST store: hash (the 20-byte address), contract flag (boolean), contract_code_hash (nullable), label (nullable text for ENS or known names), and first_seen_at timestamp.

#### Scenario: New address discovered during indexing
- **WHEN** a transaction references an address not yet in the database for that chain
- **THEN** the system creates an address record with `first_seen_at` set to the block timestamp

#### Scenario: Same address on different chains
- **WHEN** the same 20-byte address exists on Ethereum and Optimism
- **THEN** two separate address records exist, one per chain, each with independent metadata

### Requirement: Token transfer tracking
The system SHALL store token transfers in a `token_transfers` table. Each transfer MUST reference its parent transaction and store: from_address, to_address, token_contract_address, amount (as a decimal/numeric to handle large uint256 values), token_type (enum: `native`, `erc20`, `erc721`, `erc1155`), and token_id (nullable, for NFTs).

#### Scenario: ERC-20 transfer extracted from logs
- **WHEN** a `Transfer(address,address,uint256)` event is emitted by an ERC-20 contract
- **THEN** the system stores a token transfer with `token_type` = `erc20` and the decoded amount

#### Scenario: Native ETH transfer
- **WHEN** a transaction transfers ETH via `value` field
- **THEN** the system stores a token transfer with `token_type` = `native`

### Requirement: Event log storage
The system SHALL store event logs in a `logs` table. Each log MUST reference its parent transaction and store: log_index, contract_address, topic0 through topic3, data (raw bytes), and a `decoded` JSONB column (nullable, for future decoder pipeline output).

#### Scenario: Store raw event log
- **WHEN** a transaction emits events
- **THEN** all events are stored with their raw topics and data, indexed by `(chain_id, transaction_hash, log_index)`

### Requirement: Cross-chain link tracking
The system SHALL store cross-chain links in a `cross_chain_links` table. A link connects two transactions on different chains that are part of the same user journey (e.g., L1 deposit → L2 relay). Each link MUST store: source_chain_id, source_tx_hash, destination_chain_id, destination_tx_hash (nullable — destination may not yet be indexed), link_type (enum: `deposit`, `withdrawal`, `relay`), message_hash (the canonical bridge message identifier), and status (enum: `initiated`, `relayed`, `proven`, `finalized`).

#### Scenario: L1 deposit linked to L2 relay
- **WHEN** an L1 deposit transaction is indexed AND the corresponding L2 relay transaction is later indexed
- **THEN** a cross-chain link is created with both hashes, link_type `deposit`, and status `relayed`

#### Scenario: L2 withdrawal initiated but not yet proven
- **WHEN** an L2 withdrawal initiation is indexed but no L1 proof transaction exists yet
- **THEN** a cross-chain link is created with `destination_tx_hash` = NULL and status `initiated`

### Requirement: Token registry with cross-chain address mapping
The system SHALL maintain a `tokens` table for canonical token definitions and a `token_addresses` table mapping tokens to their per-chain contract addresses. The `tokens` table MUST store: name, symbol, decimals, and logo_url (nullable). The `token_addresses` table MUST store: token_id (FK), chain_id (FK), and contract_address. A token_address MUST be uniquely identified by `(chain_id, contract_address)`.

#### Scenario: Same token on multiple chains
- **WHEN** USDC exists on Ethereum (0xA0b8...) and Optimism (0x0b2C...)
- **THEN** one `tokens` record exists for USDC, with two `token_addresses` records — one per chain

#### Scenario: Token transfer references token registry
- **WHEN** a token transfer is stored for a known ERC-20 contract
- **THEN** it can be joined to the `token_addresses` table to resolve the token's name, symbol, and decimals

#### Scenario: Unknown token address
- **WHEN** a transfer involves a contract address not yet in the `token_addresses` table
- **THEN** the transfer is still stored; the token_address association is optional (nullable FK or join-based)

### Requirement: Decoded summary versioning
The `operations` table SHALL include a `decoder_version` column (integer, nullable). When an operation's `decoded_summary` is populated, `decoder_version` MUST be set to the current decoder version. This enables background reprocessing of stale summaries when the decoder is improved.

#### Scenario: Operation indexed with current decoder
- **WHEN** an operation is created and the decoder generates a summary
- **THEN** `decoded_summary` is set to the human-readable text and `decoder_version` is set to the current version number

#### Scenario: Trivial operation skips decoding
- **WHEN** a simple ETH transfer operation is created
- **THEN** `decoded_summary` MAY be NULL — the UI can generate trivial summaries on the fly

#### Scenario: Decoder upgraded triggers reprocessing
- **WHEN** the decoder version is incremented
- **THEN** a background job can query `WHERE decoder_version < current_version` to find operations that need re-decoding

### Requirement: Chain registry
The system SHALL maintain a `chains` table. Each chain record MUST store: chain_id (the EIP-155 chain ID), name, chain_type (enum: `l1`, `optimistic_rollup`, `zk_rollup`, `sidechain`), native_token_symbol, explorer_slug (for URL routing, e.g., `ethereum`, `optimism`), rpc_endpoint configuration, and enabled flag.

#### Scenario: Query supported chains
- **WHEN** the system starts up
- **THEN** the chains table contains pre-seeded records for all configured chains with their EIP-155 chain IDs
