## ADDED Requirements

### Requirement: Block query module
The system SHALL provide `Rexplorer.Blocks` with functions: `get_block(chain_id, block_number)`, `list_blocks(chain_id, opts)` (with cursor pagination). Both MUST preload transaction counts.

#### Scenario: Get block with transaction count
- **WHEN** `Rexplorer.Blocks.get_block(1, 20_000_000)` is called
- **THEN** it returns `{:ok, block}` with a `transaction_count` virtual field

#### Scenario: List blocks with pagination
- **WHEN** `Rexplorer.Blocks.list_blocks(1, limit: 10, cursor: 19_999_990)` is called
- **THEN** it returns `{:ok, blocks, next_cursor}` with 10 blocks before the cursor

### Requirement: Transaction query module
The system SHALL provide `Rexplorer.Transactions` with functions: `get_transaction(chain_id, hash)`, `get_full_transaction(chain_id, hash)` (with preloaded operations, transfers, logs, cross-chain links), `list_transactions(chain_id, opts)` (with optional address filter and cursor pagination).

#### Scenario: Get full transaction with associations
- **WHEN** `Rexplorer.Transactions.get_full_transaction(1, "0xabc...")` is called
- **THEN** it returns the transaction with operations, token_transfers, logs, cross_chain_links, and frames preloaded

#### Scenario: Get full frame transaction with frames
- **WHEN** `Rexplorer.Transactions.get_full_transaction(1, "0xabc...")` is called for a frame transaction
- **THEN** it returns the transaction with frames preloaded in order

#### Scenario: List transactions for address
- **WHEN** `Rexplorer.Transactions.list_transactions(1, address: "0xabc...", limit: 25)` is called
- **THEN** it returns transactions where the address is sender or recipient

### Requirement: Address query module
The system SHALL provide `Rexplorer.Addresses` with functions: `get_address(chain_id, hash)`, `get_address_overview(chain_id, hash)` (with recent transactions, token transfers, and current balance).

#### Scenario: Get address overview
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xabc...")` is called
- **THEN** it returns the address with recent transactions, token transfers, and `current_balance_wei` included on the address struct

#### Scenario: Address overview for address with no balance
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xabc...")` is called for an address with no balance data
- **THEN** the address struct has `current_balance_wei = nil`

#### Scenario: Address overview includes frame-targeted transactions
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xUniswap")` is called and a frame tx has a SENDER frame targeting 0xUniswap
- **THEN** that frame transaction appears in the recent transactions list

### Requirement: Balance query module
The system SHALL provide `Rexplorer.Balances` with functions for querying balance data. This module is separate from `Rexplorer.Addresses` because balance history queries are distinct from address metadata queries.

#### Scenario: Module exists and is accessible
- **WHEN** `Rexplorer.Balances` is called
- **THEN** the module is available with `get_current_balance/2` and `get_balance_history/3` functions

### Requirement: Chain query module
The system SHALL provide `Rexplorer.Chains` with functions: `list_enabled_chains()`, `get_chain_by_slug(slug)`.

#### Scenario: Get chain by slug
- **WHEN** `Rexplorer.Chains.get_chain_by_slug("ethereum")` is called
- **THEN** it returns `{:ok, chain}` for the Ethereum chain record

#### Scenario: Unknown slug
- **WHEN** `Rexplorer.Chains.get_chain_by_slug("nonexistent")` is called
- **THEN** it returns `{:error, :not_found}`

### Requirement: Search module
The system SHALL provide `Rexplorer.Search.query(input, opts)` that classifies the input (tx hash, block number, address) and returns matching results across chains (or scoped to a specific chain if provided).

#### Scenario: Search identifies transaction hash
- **WHEN** `Rexplorer.Search.query("0x" <> 64_hex_chars)` is called
- **THEN** it classifies as `:transaction` and searches the transactions table

#### Scenario: Search identifies address
- **WHEN** `Rexplorer.Search.query("0x" <> 40_hex_chars)` is called
- **THEN** it classifies as `:address` and searches the addresses table

#### Scenario: Search identifies block number
- **WHEN** `Rexplorer.Search.query("20000000")` is called
- **THEN** it classifies as `:block_number` and searches the blocks table

### Requirement: Internal transactions query module
The system SHALL provide `Rexplorer.InternalTransactions` with functions for querying internal transactions by address. This module MUST use the two-query union pattern (separate queries on `from_address` and `to_address` indexes, merged in Elixir) for efficient address lookups.

#### Scenario: Module exists and is accessible
- **WHEN** `Rexplorer.InternalTransactions` is called
- **THEN** the module is available with `list_by_address/3` function
