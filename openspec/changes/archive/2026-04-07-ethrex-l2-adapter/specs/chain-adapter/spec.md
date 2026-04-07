## MODIFIED Requirements

### Requirement: Chain adapter registry
The system SHALL maintain a registry of available chain adapters, accessible via `Rexplorer.Chain.Registry`. The registry SHALL provide:

- `get_adapter/1` — given a chain_id, returns the adapter module (or parameterized adapter struct)
- `list_adapters/0` — returns all registered adapters (including dynamic Ethrex instances)
- `enabled_adapters/0` — returns adapters for chains marked as enabled in the `chains` table

Adapters SHALL be registered at application startup via configuration. The configuration SHALL include:
- Hardcoded module adapters: Ethereum (1), Optimism (10), Base (8453), BNB (56), Polygon (137)
- Config-driven Ethrex adapters: dynamically created from `:rexplorer, :ethrex_chains` config

#### Scenario: Look up hardcoded adapter
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(1)` is called
- **THEN** it returns `{:ok, Rexplorer.Chain.Ethereum}`

#### Scenario: Look up dynamic Ethrex adapter
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(12345)` is called and chain 12345 is an Ethrex deployment
- **THEN** it returns `{:ok, adapter}` where adapter responds to all `Rexplorer.Chain.Adapter` callbacks with Ethrex-specific values

#### Scenario: Unknown chain ID
- **WHEN** `Rexplorer.Chain.Registry.get_adapter(999999)` is called
- **THEN** it returns `{:error, :unknown_chain}`
