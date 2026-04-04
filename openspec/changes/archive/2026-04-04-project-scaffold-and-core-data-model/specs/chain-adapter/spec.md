## ADDED Requirements

### Requirement: Chain adapter behaviour definition
The system SHALL define an Elixir behaviour `Rexplorer.Chain.Adapter` that all chain implementations MUST implement. The behaviour SHALL define the following callbacks:

- `chain_id/0` — returns the EIP-155 chain ID (integer)
- `chain_type/0` — returns the chain type atom (`:l1`, `:optimistic_rollup`, `:zk_rollup`, `:sidechain`)
- `native_token/0` — returns `{symbol, decimals}` tuple
- `block_fields/0` — returns a list of chain-specific field definitions for the `chain_extra` JSONB column
- `transaction_fields/0` — returns a list of chain-specific field definitions for the `chain_extra` JSONB column
- `extract_operations/1` — given a transaction with decoded data, returns a list of operations (the chain may add chain-specific operation types)
- `bridge_contracts/0` — returns a list of known bridge contract addresses for cross-chain link detection

#### Scenario: Adapter implements all required callbacks
- **WHEN** a new chain adapter module is created
- **THEN** the compiler SHALL warn if any required callback is not implemented

#### Scenario: Adapter provides chain-specific block fields
- **WHEN** the Optimism adapter defines `block_fields/0`
- **THEN** it returns field definitions like `[{:l1_block_number, :integer}, {:sequence_number, :integer}]` that describe what goes in `chain_extra`

### Requirement: Ethereum mainnet reference adapter
The system SHALL include a `Rexplorer.Chain.Ethereum` module that implements the `Rexplorer.Chain.Adapter` behaviour for Ethereum mainnet (chain_id: 1). This serves as the reference implementation. It SHALL return an empty list for `block_fields/0` and `transaction_fields/0` (mainnet has no chain-specific extensions). Its `extract_operations/1` SHALL handle standard EOA calls, producing a single `call` operation per transaction.

#### Scenario: Ethereum adapter identifies itself
- **WHEN** `Rexplorer.Chain.Ethereum.chain_id/0` is called
- **THEN** it returns `1`

#### Scenario: Ethereum adapter extracts simple operation
- **WHEN** `extract_operations/1` is called with a standard EOA transfer transaction
- **THEN** it returns a list with exactly one operation of type `call`

### Requirement: Chain adapter registry
The system SHALL maintain a registry of available chain adapters, accessible via `Rexplorer.Chain.Registry`. The registry SHALL provide:

- `get_adapter/1` — given a chain_id, returns the adapter module
- `list_adapters/0` — returns all registered adapters
- `enabled_adapters/0` — returns adapters for chains marked as enabled in the `chains` table

Adapters SHALL be registered at application startup via configuration.

#### Scenario: Look up adapter by chain ID
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(1)` is called
- **THEN** it returns `{:ok, Rexplorer.Chain.Ethereum}`

#### Scenario: Unknown chain ID
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(999999)` is called
- **THEN** it returns `{:error, :unknown_chain}`

#### Scenario: List only enabled adapters
- **WHEN** Optimism is configured but disabled in the chains table
- **THEN** `enabled_adapters/0` does not include the Optimism adapter
