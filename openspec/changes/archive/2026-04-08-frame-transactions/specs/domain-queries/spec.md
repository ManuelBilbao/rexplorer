## MODIFIED Requirements

### Requirement: Transaction query module
The system SHALL provide `Rexplorer.Transactions` with functions: `get_transaction(chain_id, hash)`, `get_full_transaction(chain_id, hash)` (with preloaded operations, transfers, logs, cross-chain links, and frames for frame transactions), `list_transactions(chain_id, opts)` (with optional address filter, block_number filter, and cursor pagination).

#### Scenario: Get full frame transaction with associations
- **WHEN** `Rexplorer.Transactions.get_full_transaction(1, "0xabc...")` is called for a frame transaction
- **THEN** it returns the transaction with operations, token_transfers, logs, cross_chain_links, and frames preloaded

### Requirement: Address query module
The system SHALL provide `Rexplorer.Addresses` with functions: `get_address(chain_id, hash)`, `get_address_overview(chain_id, hash)` (with recent transactions including those found via frame targets, token transfers, and current balance).

#### Scenario: Address overview includes frame-targeted transactions
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xUniswap")` is called and a frame tx has a SENDER frame targeting 0xUniswap
- **THEN** that frame transaction appears in the recent transactions list
