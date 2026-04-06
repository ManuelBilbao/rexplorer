## MODIFIED Requirements

### Requirement: Chain adapter registry
The system SHALL maintain a registry of available chain adapters, accessible via `Rexplorer.Chain.Registry`. The registry SHALL provide:

- `get_adapter/1` — given a chain_id, returns the adapter module
- `list_adapters/0` — returns all registered adapters
- `enabled_adapters/0` — returns adapters for chains marked as enabled in the `chains` table

Adapters SHALL be registered at application startup via configuration. The configuration SHALL include all five target chains: Ethereum (1), Optimism (10), Base (8453), BNB (56), Polygon (137).

#### Scenario: Look up adapter by chain ID
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(1)` is called
- **THEN** it returns `{:ok, Rexplorer.Chain.Ethereum}`

#### Scenario: Look up Optimism adapter
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(10)` is called
- **THEN** it returns `{:ok, Rexplorer.Chain.Optimism}`

#### Scenario: Unknown chain ID
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(999999)` is called
- **THEN** it returns `{:error, :unknown_chain}`

#### Scenario: List only enabled adapters
- **WHEN** Optimism is configured but disabled in the chains table
- **THEN** `enabled_adapters/0` does not include the Optimism adapter
