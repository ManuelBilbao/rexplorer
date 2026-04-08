## ADDED Requirements

### Requirement: Internal transactions query module
The system SHALL provide `Rexplorer.InternalTransactions` with functions for querying internal transactions by address. This module MUST use the two-query union pattern (separate queries on `from_address` and `to_address` indexes, merged in Elixir) for efficient address lookups.

#### Scenario: Module exists and is accessible
- **WHEN** `Rexplorer.InternalTransactions` is called
- **THEN** the module is available with `list_by_address/3` function
