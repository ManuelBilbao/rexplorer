## MODIFIED Requirements

### Requirement: Address query module
The system SHALL provide `Rexplorer.Addresses` with functions: `get_address(chain_id, hash)`, `get_address_overview(chain_id, hash)` (with recent transactions, token transfers, and current balance).

#### Scenario: Get address overview
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xabc...")` is called
- **THEN** it returns the address with recent transactions, token transfers, and `current_balance_wei` included on the address struct

#### Scenario: Address overview for address with no balance
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xabc...")` is called for an address with no balance data
- **THEN** the address struct has `current_balance_wei = nil`

## ADDED Requirements

### Requirement: Balance query module
The system SHALL provide `Rexplorer.Balances` with functions for querying balance data. This module is separate from `Rexplorer.Addresses` because balance history queries are distinct from address metadata queries.

#### Scenario: Module exists and is accessible
- **WHEN** `Rexplorer.Balances` is called
- **THEN** the module is available with `get_current_balance/2` and `get_balance_history/3` functions
