## MODIFIED Requirements

### Requirement: Search module
The system SHALL provide `Rexplorer.Search.query(input, opts)` that classifies the input (tx hash, userOpHash, block number, address) and returns matching results across chains (or scoped to a specific chain if provided). A 66-character hex string is first looked up as a transaction hash; if nothing matches, it SHALL be looked up as a userOpHash against the stored operations, resolving to the parent transaction so the caller can navigate to it.

#### Scenario: Search identifies transaction hash
- **WHEN** `Rexplorer.Search.query("0x" <> 64_hex_chars)` is called
- **THEN** it classifies as `:transaction` and searches the transactions table

#### Scenario: Search identifies address
- **WHEN** `Rexplorer.Search.query("0x" <> 40_hex_chars)` is called
- **THEN** it classifies as `:address` and searches the addresses table

#### Scenario: Search identifies block number
- **WHEN** `Rexplorer.Search.query("20000000")` is called
- **THEN** it classifies as `:block_number` and searches the blocks table

#### Scenario: Search falls back to userOpHash
- **WHEN** a 66-character hex string matches no transaction but matches a stored userOpHash
- **THEN** it classifies as `:user_operation` and returns the parent transaction along with the userOpHash

#### Scenario: Hash matches nothing
- **WHEN** a 66-character hex string matches neither a transaction nor a userOpHash
- **THEN** the result is empty, as before

#### Scenario: Chain-scoped userOpHash search
- **WHEN** a userOpHash search is scoped to a chain
- **THEN** only operations on that chain are considered
