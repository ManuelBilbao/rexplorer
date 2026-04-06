## ADDED Requirements

### Requirement: BNB Smart Chain adapter
The system SHALL provide `Rexplorer.Chain.BNB` (chain_id: 56, chain_type: `:sidechain`, native_token: `{"BNB", 18}`, poll_interval: 3000ms). It SHALL use the EVM base module. No chain-specific block or transaction fields.

#### Scenario: BNB adapter metadata
- **WHEN** `Rexplorer.Chain.BNB.chain_id/0` is called
- **THEN** it returns `56`

#### Scenario: BNB native token is BNB
- **WHEN** `Rexplorer.Chain.BNB.native_token/0` is called
- **THEN** it returns `{"BNB", 18}`

### Requirement: Polygon adapter
The system SHALL provide `Rexplorer.Chain.Polygon` (chain_id: 137, chain_type: `:sidechain`, native_token: `{"POL", 18}`, poll_interval: 2000ms). It SHALL use the EVM base module. No chain-specific block or transaction fields.

#### Scenario: Polygon adapter metadata
- **WHEN** `Rexplorer.Chain.Polygon.chain_id/0` is called
- **THEN** it returns `137`

#### Scenario: Polygon native token is POL
- **WHEN** `Rexplorer.Chain.Polygon.native_token/0` is called
- **THEN** it returns `{"POL", 18}`
