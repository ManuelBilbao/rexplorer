## ADDED Requirements

### Requirement: Shared EVM base module
The system SHALL provide `Rexplorer.Chain.EVM` as a `__using__` macro module that injects default implementations for all `Rexplorer.Chain.Adapter` callbacks that are common across EVM chains. Specifically:
- `extract_operations/1` — delegates to `Rexplorer.Unwrapper.Registry.unwrap/2`
- `extract_token_transfers/1` — handles native token transfers and ERC-20 Transfer events
- `block_fields/0` — returns `[]` (overridable)
- `transaction_fields/0` — returns `[]` (overridable)
- `bridge_contracts/0` — returns `[]` (overridable)

Chain-specific adapters MUST override: `chain_id/0`, `chain_type/0`, `native_token/0`, `poll_interval_ms/0`. They MAY override any other callback.

#### Scenario: Adapter uses EVM base with minimal overrides
- **WHEN** a new chain adapter uses `Rexplorer.Chain.EVM` and only defines `chain_id`, `chain_type`, `native_token`, and `poll_interval_ms`
- **THEN** it inherits working `extract_operations`, `extract_token_transfers`, and empty defaults for `block_fields`, `transaction_fields`, and `bridge_contracts`

#### Scenario: Adapter overrides a default callback
- **WHEN** a chain adapter uses `Rexplorer.Chain.EVM` and also defines its own `block_fields/0`
- **THEN** the adapter's `block_fields/0` takes precedence over the default empty list

### Requirement: Ethereum adapter refactored to use EVM base
The existing `Rexplorer.Chain.Ethereum` adapter SHALL be refactored to `use Rexplorer.Chain.EVM` and only define its chain-specific metadata. All shared logic (token transfer extraction, unwrapper delegation, helpers) SHALL move to the EVM base. The adapter's external behavior MUST remain identical.

#### Scenario: Ethereum adapter behavior unchanged
- **WHEN** `Rexplorer.Chain.Ethereum.extract_operations/1` is called with a standard transaction after refactoring
- **THEN** it returns the same result as before (single `:call` operation or unwrapped operations)
