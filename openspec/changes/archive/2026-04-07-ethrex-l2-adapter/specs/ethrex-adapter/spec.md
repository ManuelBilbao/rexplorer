## ADDED Requirements

### Requirement: Ethrex stack module
The system SHALL provide `Rexplorer.Chain.Ethrex` as a module that defines Ethrex-specific adapter behavior. It SHALL use the EVM base module for shared logic and add:
- `chain_type/0` returning `:zk_rollup`
- `transaction_fields/0` returning `[{:is_privileged, :boolean}, {:l1_origin_hash, :string}, {:fee_token, :string}]`
- `block_fields/0` returning `[{:batch_number, :integer}]`

Unlike OPStack adapters which are one-module-per-chain, the Ethrex module SHALL be parameterized — a single module serving multiple chain IDs based on configuration.

#### Scenario: Ethrex adapter provides ZK rollup chain type
- **WHEN** an Ethrex adapter instance's `chain_type/0` is called
- **THEN** it returns `:zk_rollup`

#### Scenario: Ethrex adapter has privileged tx fields
- **WHEN** an Ethrex adapter instance's `transaction_fields/0` is called
- **THEN** it returns fields including `is_privileged`, `l1_origin_hash`, and `fee_token`

#### Scenario: Ethrex adapter has batch_number block field
- **WHEN** an Ethrex adapter instance's `block_fields/0` is called
- **THEN** it returns `[{:batch_number, :integer}]`

### Requirement: Config-driven Ethrex chain registration
Ethrex chains SHALL be defined in application config under `:rexplorer, :ethrex_chains` as a list of maps, each containing: `chain_id` (integer), `name` (string), `rpc_url` (string), `poll_interval_ms` (integer), and `bridge_address` (string). At startup, the Registry SHALL create one adapter instance per config entry.

#### Scenario: Add Ethrex chain via config only
- **WHEN** a new entry is added to `ethrex_chains` config with chain_id 12345
- **THEN** the Registry creates an adapter for chain 12345 without any new Elixir module

#### Scenario: Ethrex adapter returns config values
- **WHEN** `chain_id/0` is called on the adapter instance for chain 12345
- **THEN** it returns `12345`

#### Scenario: Ethrex adapter returns configured bridge
- **WHEN** `bridge_contracts/0` is called on the adapter for chain 12345
- **THEN** it returns the bridge address from the config

#### Scenario: Multiple Ethrex chains coexist
- **WHEN** two Ethrex chains are configured (chain_id 12345 and 67890)
- **THEN** the Registry has separate adapter instances for each, both queryable via `get_adapter/1`
