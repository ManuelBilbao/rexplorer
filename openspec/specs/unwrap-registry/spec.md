## Purpose

The behaviour and registry that route a transaction to the unwrapper for its wrapper pattern.

## Requirements

### Requirement: Unwrapper behaviour
The system SHALL define a `Rexplorer.Unwrapper` behaviour with callbacks:
- `matches?/2` — given a transaction map (with `to_address`, `input`) and chain_id, returns whether this unwrapper handles it
- `unwrap/2` — given the transaction map and chain_id, returns a list of operation attribute maps

The transaction map MAY additionally carry `:logs`, the transaction's decoded event logs, for unwrappers whose inner operations are only fully described by the events the wrapper emitted. An unwrapper MUST work without that key: when it is absent, the unwrapper produces whatever it can from calldata alone rather than failing or refusing to match.

#### Scenario: Unwrapper matches a Safe transaction
- **WHEN** `matches?` is called with a transaction whose input starts with the `execTransaction` selector
- **THEN** the Safe unwrapper returns `true`

#### Scenario: Unwrapper does not match
- **WHEN** `matches?` is called with a plain ERC-20 transfer
- **THEN** all unwrappers return `false`

#### Scenario: Unwrapper reads logs when present
- **WHEN** a transaction map carrying `:logs` is unwrapped
- **THEN** an unwrapper that uses events may enrich its operations from them

#### Scenario: Unwrapper works without logs
- **WHEN** the same transaction map is unwrapped without `:logs`
- **THEN** the same operations are produced, minus only the fields that come from events

### Requirement: Unwrapper registry
The system SHALL provide `Rexplorer.Unwrapper.Registry.unwrap/2` that takes a transaction map and chain_id, iterates through registered unwrappers, and returns operations from the first match. If no unwrapper matches, it SHALL return a single `:call` operation (the current default behavior). The registered unwrappers are ERC-4337, Safe and Multicall; because detection is by selector, at most one can match a given transaction, so registration order does not change the outcome.

#### Scenario: Safe transaction unwrapped
- **WHEN** a transaction calling `execTransaction` is passed to the registry
- **THEN** it returns one `:multisig_execution` operation with the inner call

#### Scenario: Plain transaction falls through
- **WHEN** a standard EOA transfer is passed to the registry
- **THEN** it returns one `:call` operation (same as current behavior)

#### Scenario: Multicall transaction unwrapped
- **WHEN** a transaction calling `multicall(bytes[])` is passed to the registry
- **THEN** it returns N `:multicall_item` operations, one per inner call

#### Scenario: Bundle transaction unwrapped
- **WHEN** a transaction calling `handleOps` is passed to the registry
- **THEN** it returns `:user_operation` operations, one or more per UserOperation in the bundle

#### Scenario: Unwrapper raises
- **WHEN** a registered unwrapper raises while unwrapping
- **THEN** the registry returns a single `:call` operation and indexing continues
