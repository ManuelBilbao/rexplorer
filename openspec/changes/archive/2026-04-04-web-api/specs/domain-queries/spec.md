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
- **THEN** it returns the transaction with operations, token_transfers, logs, and cross_chain_links preloaded

#### Scenario: List transactions for address
- **WHEN** `Rexplorer.Transactions.list_transactions(1, address: "0xabc...", limit: 25)` is called
- **THEN** it returns transactions where the address is sender or recipient

### Requirement: Address query module
The system SHALL provide `Rexplorer.Addresses` with functions: `get_address(chain_id, hash)`, `get_address_overview(chain_id, hash)` (with recent transactions and token transfers).

#### Scenario: Get address overview
- **WHEN** `Rexplorer.Addresses.get_address_overview(1, "0xabc...")` is called
- **THEN** it returns the address with recent transactions and token transfers preloaded

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
