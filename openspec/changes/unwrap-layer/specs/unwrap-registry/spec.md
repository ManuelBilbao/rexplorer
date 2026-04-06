## ADDED Requirements

### Requirement: Unwrapper behaviour
The system SHALL define a `Rexplorer.Unwrapper` behaviour with callbacks:
- `matches?/2` — given a transaction map (with `to_address`, `input`) and chain_id, returns whether this unwrapper handles it
- `unwrap/2` — given the transaction map and chain_id, returns a list of operation attribute maps

#### Scenario: Unwrapper matches a Safe transaction
- **WHEN** `matches?` is called with a transaction whose input starts with the `execTransaction` selector
- **THEN** the Safe unwrapper returns `true`

#### Scenario: Unwrapper does not match
- **WHEN** `matches?` is called with a plain ERC-20 transfer
- **THEN** all unwrappers return `false`

### Requirement: Unwrapper registry
The system SHALL provide `Rexplorer.Unwrapper.Registry.unwrap/2` that takes a transaction map and chain_id, iterates through registered unwrappers, and returns operations from the first match. If no unwrapper matches, it SHALL return a single `:call` operation (the current default behavior).

#### Scenario: Safe transaction unwrapped
- **WHEN** a transaction calling `execTransaction` is passed to the registry
- **THEN** it returns one `:multisig_execution` operation with the inner call

#### Scenario: Plain transaction falls through
- **WHEN** a standard EOA transfer is passed to the registry
- **THEN** it returns one `:call` operation (same as current behavior)

#### Scenario: Multicall transaction unwrapped
- **WHEN** a transaction calling `multicall(bytes[])` is passed to the registry
- **THEN** it returns N `:multicall_item` operations, one per inner call
