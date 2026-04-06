## ADDED Requirements

### Requirement: OP Stack shared module
The system SHALL provide `Rexplorer.Chain.OPStack` as a `__using__` macro module that layers OP Stack-specific behavior on top of the EVM base. It SHALL override:
- `block_fields/0` — returns `[{:l1_block_number, :integer}, {:sequence_number, :integer}]`
- `transaction_fields/0` — returns `[{:source_hash, :string}, {:mint, :integer}, {:is_system_tx, :boolean}]`

OP Stack adapters MUST still define their own `chain_id/0`, `chain_type/0`, `native_token/0`, `poll_interval_ms/0`, and `bridge_contracts/0`.

#### Scenario: OP Stack adapter has L2 block fields
- **WHEN** `Rexplorer.Chain.Optimism.block_fields/0` is called
- **THEN** it returns `[{:l1_block_number, :integer}, {:sequence_number, :integer}]`

#### Scenario: OP Stack adapter has deposit tx fields
- **WHEN** `Rexplorer.Chain.Base.transaction_fields/0` is called
- **THEN** it returns `[{:source_hash, :string}, {:mint, :integer}, {:is_system_tx, :boolean}]`

### Requirement: Optimism adapter
The system SHALL provide `Rexplorer.Chain.Optimism` (chain_id: 10, chain_type: `:optimistic_rollup`, native_token: `{"ETH", 18}`, poll_interval: 2000ms). It SHALL use both EVM base and OPStack modules. Bridge contracts SHALL include the Optimism Portal address.

#### Scenario: Optimism adapter metadata
- **WHEN** `Rexplorer.Chain.Optimism.chain_id/0` is called
- **THEN** it returns `10`

### Requirement: Base adapter
The system SHALL provide `Rexplorer.Chain.Base` (chain_id: 8453, chain_type: `:optimistic_rollup`, native_token: `{"ETH", 18}`, poll_interval: 2000ms). It SHALL use both EVM base and OPStack modules. Bridge contracts SHALL include the Base Portal address.

#### Scenario: Base adapter metadata
- **WHEN** `Rexplorer.Chain.Base.chain_id/0` is called
- **THEN** it returns `8453`
