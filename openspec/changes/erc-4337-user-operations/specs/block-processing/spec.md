## MODIFIED Requirements

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

## ADDED Requirements

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
