## MODIFIED Requirements

### Requirement: Address tracking
The system SHALL maintain an `addresses` table. Each address MUST be uniquely identified by `(chain_id, hash)`. Addresses MUST store: hash (the 20-byte address), contract flag (boolean), contract_code_hash (nullable), label (nullable text for ENS or known names), first_seen_at timestamp, and `current_balance_wei` (nullable numeric — the latest known native-token balance in Wei, updated by the indexer whenever a new balance change is recorded).

#### Scenario: New address discovered during indexing
- **WHEN** a transaction references an address not yet in the database for that chain
- **THEN** the system creates an address record with `first_seen_at` set to the block timestamp

#### Scenario: Same address on different chains
- **WHEN** the same 20-byte address exists on Ethereum and Optimism
- **THEN** two separate address records exist, one per chain, each with independent metadata

#### Scenario: Balance updated on address record
- **WHEN** a new `balance_changes` row is inserted for an address
- **THEN** the `current_balance_wei` field on the `addresses` row is updated to match the new balance

#### Scenario: Address with no balance data
- **WHEN** an address exists but has never been tracked for balance
- **THEN** `current_balance_wei` is NULL
