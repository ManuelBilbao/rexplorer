## MODIFIED Requirements

### Requirement: Operation abstraction
The system SHALL store operations in an `operations` table. An operation represents a single user intent extracted from a transaction. A transaction MAY contain one or more operations. Each operation MUST reference its parent transaction and store: operation_type (enum: `call`, `user_operation`, `multisig_execution`, `multicall_item`, `delegate_call`), operation_index within the transaction, from_address (the logical sender), to_address, value, input data, decoded_summary (nullable text for the human-readable narration), and `op_extra` (a JSON object, defaulting to empty, holding structured facts that belong to the operation but have no column of their own — the ERC-4337 fields `user_op_hash`, `user_op_index`, `entry_point`, `entry_point_version`, `paymaster`, `factory`, `success` and `actual_gas_cost`).

#### Scenario: Simple EOA transaction produces one operation
- **WHEN** a standard EOA-to-EOA transfer is processed
- **THEN** exactly one operation with type `call` is created, referencing the transaction, with an empty `op_extra`

#### Scenario: AA bundler transaction produces multiple operations
- **WHEN** an ERC-4337 `handleOps` bundler transaction is processed
- **THEN** at least one operation of type `user_operation` is created per UserOperation in the bundle, each with its own logical `from_address` (the smart wallet sender) and an `op_extra` carrying that UserOperation's hash, index and EntryPoint

#### Scenario: Batched UserOperation produces one operation per inner call
- **WHEN** a UserOperation batches several calls
- **THEN** one `user_operation` operation is created per inner call, all sharing the same `user_op_index` and `user_op_hash` in `op_extra`

#### Scenario: Sponsored UserOperation records its paymaster
- **WHEN** a UserOperation is paid for by a paymaster
- **THEN** the operation's `op_extra` carries the paymaster address, and an unsponsored one carries none

#### Scenario: Safe multisig execution produces wrapped operation
- **WHEN** a Safe `execTransaction` call is processed
- **THEN** one operation of type `multisig_execution` is created, with `from_address` set to the Safe address and the inner call data stored in `input`

#### Scenario: Multicall produces multiple operations
- **WHEN** a `multicall()` transaction is processed
- **THEN** one operation of type `multicall_item` is created per inner call, ordered by `operation_index`

#### Scenario: Operation from SENDER frame
- **WHEN** a SENDER frame is decoded into an operation
- **THEN** the operation is stored with `frame_index` set to the frame's index

#### Scenario: Operation from regular transaction
- **WHEN** a regular transaction produces an operation
- **THEN** the operation is stored with `frame_index = NULL`

#### Scenario: Lookup by userOpHash
- **WHEN** an operation is searched for by the userOpHash held in its `op_extra`, scoped to a chain
- **THEN** the lookup is index-backed rather than a full scan of the operations table
