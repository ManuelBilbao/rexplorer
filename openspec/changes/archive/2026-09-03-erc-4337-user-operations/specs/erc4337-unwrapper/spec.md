## Purpose

Decomposes an ERC-4337 bundler transaction into the user intents it carries, so that each UserOperation is attributed to the smart account that authored it rather than to the bundler EOA that submitted the bundle.

## ADDED Requirements

### Requirement: handleOps detection
The system SHALL detect `handleOps` calls by 4-byte selector, covering both EntryPoint calldata shapes:
- `handleOps((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)` — EntryPoint v0.6, unpacked `UserOperation[]`
- `handleOps((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[],address)` — EntryPoint v0.7 and v0.8, `PackedUserOperation[]`

Detection MUST be selector-based, not address-based: EntryPoint deployments differ per version and a chain may host several at once.

The recorded EntryPoint version is a separate question from detection. v0.8 kept v0.7's calldata shape, so the version SHALL be taken from the canonical EntryPoint addresses where the transaction was sent to one, falling back to the calldata shape otherwise.

#### Scenario: Detect a v0.6 bundle
- **WHEN** a transaction's input starts with the v0.6 `handleOps` selector
- **THEN** the ERC-4337 unwrapper matches and records the EntryPoint version as `0.6`

#### Scenario: Detect a v0.7 bundle
- **WHEN** a transaction's input starts with the packed `handleOps` selector and was sent to the canonical v0.7 EntryPoint
- **THEN** the ERC-4337 unwrapper matches and records the EntryPoint version as `0.7`

#### Scenario: A v0.8 bundle is named by its address
- **WHEN** a packed bundle was sent to the canonical v0.8 EntryPoint, whose calldata is identical to v0.7's
- **THEN** the recorded version is `0.8`

#### Scenario: A non-canonical EntryPoint deployment
- **WHEN** a packed bundle was sent to an EntryPoint address the system does not know
- **THEN** it still unwraps, and the version falls back to the calldata shape

#### Scenario: Non-bundle transaction
- **WHEN** a transaction calls any other function
- **THEN** the ERC-4337 unwrapper does not match and other unwrappers are consulted

#### Scenario: Aggregated bundle is not claimed
- **WHEN** a transaction calls `handleAggregatedOps`
- **THEN** the ERC-4337 unwrapper does not match, and the transaction falls through to a single `call` operation

### Requirement: UserOperation decoding
When a bundle is detected, the system SHALL decode the operations array and extract, per UserOperation: `sender` (the smart account), `nonce`, `initCode`, `callData`, and `paymasterAndData`. The EntryPoint address SHALL be taken from the transaction's `to_address`. Each resulting operation MUST have `operation_type` `user_operation` and `from_address` set to the UserOperation's `sender` — never the bundler EOA.

#### Scenario: Bundle with three UserOperations
- **WHEN** a `handleOps` transaction carries three UserOperations from three different smart accounts
- **THEN** at least three `user_operation` operations are produced, each with `from_address` set to its own sender

#### Scenario: Sender attribution
- **WHEN** a user views a bundle that contains their UserOperation
- **THEN** the operation is attributed to their smart account address, and the bundler EOA appears only as the transaction sender

#### Scenario: Sequential operation indexing
- **WHEN** a bundle produces N operations in total
- **THEN** `operation_index` runs 0..N-1 across the whole transaction, and every operation carries the `user_op_index` of the UserOperation it came from

### Requirement: Account call fan-out
A UserOperation's `callData` is a call to the smart account itself, so the system SHALL peel that second layer to reveal the real target:
- `execute(address,uint256,bytes)` — one operation, with `to_address` and `value` from the inner call and `input` set to the inner calldata
- `executeBatch(address[],bytes[])` and `executeBatch(address[],uint256[],bytes[])` — one operation per inner call, each with its own target, value and calldata
- any other `callData` — one operation with `to_address` set to the smart account and `input` set to the raw `callData`

All operations derived from the same UserOperation MUST share the same `user_op_index`, `user_op_hash` and paymaster, so they can be grouped back into one UserOperation for display.

#### Scenario: Single execute
- **WHEN** a UserOperation's callData is `execute` wrapping an ERC-20 transfer
- **THEN** one operation is produced whose target is the token contract and whose input is the transfer calldata, so the decoder narrates the transfer rather than "Called execute"

#### Scenario: Batched UserOperation
- **WHEN** a UserOperation's callData is `executeBatch` wrapping an approve and a swap
- **THEN** two operations are produced, each independently decodable, both sharing one `user_op_index` and one `user_op_hash`

#### Scenario: Unrecognized account interface
- **WHEN** a UserOperation's callData uses a wallet-specific execution selector the system does not know
- **THEN** one operation is produced targeting the smart account with the raw callData preserved, so no information is lost

#### Scenario: Empty callData
- **WHEN** a UserOperation carries empty callData (a deployment-only operation)
- **THEN** one operation is produced targeting the smart account with no input

### Requirement: UserOperationEvent correlation
The EntryPoint emits one `UserOperationEvent(bytes32 indexed userOpHash, address indexed sender, address indexed paymaster, uint256 nonce, bool success, uint256 actualGasCost, uint256 actualGasUsed)` per UserOperation, in bundle order. When the transaction's logs are available, the system SHALL match those events to the decoded UserOperations by position and record `user_op_hash`, `paymaster`, `success` and `actual_gas_cost` on every operation derived from each one. The event is authoritative: where it disagrees with the calldata, the event value wins.

#### Scenario: Hash and outcome recorded
- **WHEN** a bundle's logs contain a `UserOperationEvent` for each UserOperation
- **THEN** each operation records the userOpHash and the per-operation success flag from its event

#### Scenario: One UserOperation reverts
- **WHEN** a bundle succeeds at the transaction level but one UserOperation's event reports `success = false`
- **THEN** only that UserOperation's operations are marked unsuccessful, and the other UserOperations in the bundle stay successful

#### Scenario: Event count mismatch
- **WHEN** the number of `UserOperationEvent` logs does not equal the number of decoded UserOperations
- **THEN** correlation is skipped rather than mismatched, and operations are produced from calldata alone

#### Scenario: Logs unavailable
- **WHEN** operations are extracted without receipt logs
- **THEN** operations are still produced from calldata, with `user_op_hash`, `success` and `actual_gas_cost` absent

### Requirement: Paymaster and factory extraction
The system SHALL record the paymaster address for a sponsored UserOperation and the factory address for one that deploys its account. Both are the leading 20 bytes of a variable-length field — `paymasterAndData` and `initCode` respectively — and MUST be omitted when that field is empty. This holds for both EntryPoint shapes, where the surrounding encoding differs but the prefix does not.

#### Scenario: Sponsored operation
- **WHEN** a UserOperation carries a non-empty `paymasterAndData`
- **THEN** the paymaster address is recorded on every operation derived from that UserOperation

#### Scenario: Self-funded operation
- **WHEN** a UserOperation carries empty `paymasterAndData`
- **THEN** no paymaster is recorded and the operation is treated as self-funded

#### Scenario: Account deployment
- **WHEN** a UserOperation carries a non-empty `initCode`
- **THEN** the factory address is recorded, marking this as the operation that deployed the smart account

### Requirement: Malformed bundle fallback
Detection is selector-based and therefore optimistic. When a transaction matches `handleOps` but its calldata cannot be decoded, the operations array is empty, or decoding raises, the system SHALL fall back to a single `call` operation for the transaction rather than dropping it or producing partial data.

#### Scenario: Undecodable bundle
- **WHEN** a transaction carries the `handleOps` selector followed by calldata that does not decode
- **THEN** one `call` operation is produced, identical to the behaviour before this capability existed

#### Scenario: Empty bundle
- **WHEN** a `handleOps` transaction carries an empty operations array
- **THEN** one `call` operation is produced

### Requirement: Chain independence
UserOperation unwrapping SHALL apply to every EVM chain the explorer indexes, without per-chain configuration. ERC-4337 is a contract-level standard with the same calldata on every chain, so a bundle on an L2 unwraps exactly as one on Ethereum.

#### Scenario: Bundle on an L2
- **WHEN** a `handleOps` transaction is indexed on Base or Optimism
- **THEN** it unwraps into the same operations it would produce on Ethereum

#### Scenario: New chain adapter
- **WHEN** a chain adapter is added for a chain with an EntryPoint deployed
- **THEN** AA unwrapping works with no adapter-side code
