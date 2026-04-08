## ADDED Requirements

### Requirement: Balance changes table
The system SHALL maintain a `balance_changes` table that records the absolute native-token balance of an address at every block where that balance changed. Each row MUST be uniquely identified by `(chain_id, address_hash, block_number)` and MUST store: `balance_wei` (numeric), `timestamp` (from the block), and `source` (enum: `seed`, `indexed`).

#### Scenario: Balance change recorded during indexing
- **WHEN** block N is indexed and address 0xABC's balance at block N differs from its last known balance
- **THEN** a row is inserted with `chain_id`, `address_hash = "0xabc..."`, `block_number = N`, `balance_wei` = result of `eth_getBalance(0xABC, N)`, `source = "indexed"`

#### Scenario: Balance unchanged — no row inserted
- **WHEN** block N is indexed and address 0xABC is touched but its balance at block N equals its last known balance
- **THEN** no `balance_changes` row is inserted for that address at that block

#### Scenario: Reject duplicate balance entries
- **WHEN** a balance change for `(chain_id, address_hash, block_number)` already exists
- **THEN** the system SHALL enforce uniqueness and reject the duplicate

### Requirement: Seed row for first-seen addresses
When an address is encountered for the first time during indexing at block N, the system SHALL fetch `eth_getBalance(address, N-1)` and insert a seed row at block N-1 with `source = "seed"`. This establishes the balance baseline before the first indexed change.

#### Scenario: First-time address receives seed
- **WHEN** address 0xABC is first seen in block 500 and its balance at block 499 is 3.0 ETH
- **THEN** a `balance_changes` row is inserted with `block_number = 499`, `balance_wei = 3000000000000000000`, `source = "seed"`
- **AND** a second row is inserted for block 500 with the new balance and `source = "indexed"`

#### Scenario: Seed fetch fails (pruned state)
- **WHEN** address 0xABC is first seen in block 500 but `eth_getBalance(0xABC, 499)` fails
- **THEN** the system SHALL skip the seed row and insert only the block 500 row with `source = "indexed"`
- **AND** a warning SHALL be logged

#### Scenario: First-time address with unchanged balance
- **WHEN** address 0xABC is first seen in block 500 and its balance at block 499 equals its balance at block 500
- **THEN** only the seed row at block 499 is inserted (no block 500 row since balance did not change)

### Requirement: Touched address collection via traces
On chains where the adapter supports traces, the system SHALL call `debug_traceBlockByNumber` with the `callTracer` tracer and recursively flatten the nested call tree to extract all addresses involved in value transfers (CALL, CREATE, SELFDESTRUCT). These addresses SHALL be merged with addresses from top-level transactions, the block miner, and withdrawal recipients to form the complete set of touched addresses.

#### Scenario: Internal call discovered via trace
- **WHEN** block N contains a transaction where contract A calls contract B with 1 ETH (internal transfer)
- **THEN** both A and B are included in the touched address set, even though B does not appear in the top-level transaction fields

#### Scenario: Nested calls flattened
- **WHEN** a transaction trace shows A → B → C → D (nested calls)
- **THEN** all four addresses (A, B, C, D) are included in the touched address set

#### Scenario: Self-destruct recipient captured
- **WHEN** a transaction trace includes a SELFDESTRUCT sending remaining balance to address X
- **THEN** X is included in the touched address set

#### Scenario: Miner and withdrawal recipients included
- **WHEN** block N has miner M and withdrawals to addresses W1 and W2
- **THEN** M, W1, and W2 are included in the touched address set regardless of trace results

### Requirement: Fallback address collection without traces
On chains where the adapter does not support traces, the system SHALL collect touched addresses from: transaction `from_address` and `to_address` fields, the block miner address, and withdrawal recipient addresses. This provides partial but correct coverage.

#### Scenario: No trace support — top-level addresses only
- **WHEN** block N is indexed on a chain without trace support and contains a transaction from A to B
- **THEN** A and B are included in the touched address set
- **AND** internal call recipients are NOT included (partial coverage)

### Requirement: Balance fetching for touched addresses
For each unique address in the touched set, the system SHALL call `eth_getBalance(address, blockNumber)` to obtain the absolute balance at that block. The system SHALL compare this with the address's last known balance in the database and only insert a `balance_changes` row if the balance differs.

#### Scenario: Balance fetched and compared
- **WHEN** address 0xABC is touched in block 500 and `eth_getBalance` returns 5.0 ETH, but the last known balance is 4.5 ETH
- **THEN** a `balance_changes` row is inserted with `balance_wei = 5000000000000000000`

#### Scenario: Balance fetch fails
- **WHEN** `eth_getBalance` for address 0xABC at block 500 fails
- **THEN** the system SHALL log a warning and skip balance tracking for that address at that block
- **AND** block indexing SHALL NOT be aborted

### Requirement: Current balance query
The system SHALL provide `Rexplorer.Balances.get_current_balance(chain_id, address_hash)` that returns the current native-token balance for an address. This MUST read from the denormalized `current_balance_wei` field on the `addresses` table for performance.

#### Scenario: Address with known balance
- **WHEN** `get_current_balance(1, "0xabc...")` is called for an address with indexed balance data
- **THEN** it returns `{:ok, balance_wei}` where `balance_wei` is the latest known balance

#### Scenario: Address with no balance data
- **WHEN** `get_current_balance(1, "0xabc...")` is called for an address with no balance data (e.g., `current_balance_wei` is NULL)
- **THEN** it returns `{:ok, nil}`

### Requirement: Balance history query
The system SHALL provide `Rexplorer.Balances.get_balance_history(chain_id, address_hash, opts)` that returns a time-ordered list of `{block_number, balance_wei, timestamp}` tuples for charting. The function MUST support cursor-based pagination via `:before` (block_number) and `:limit` options.

#### Scenario: Full balance history
- **WHEN** `get_balance_history(1, "0xabc...")` is called
- **THEN** it returns `{:ok, entries}` where entries is a list of `%{block_number, balance_wei, timestamp}` ordered by block_number ascending

#### Scenario: Paginated balance history
- **WHEN** `get_balance_history(1, "0xabc...", before: 1000, limit: 50)` is called
- **THEN** it returns at most 50 entries with `block_number < 1000`, ordered by block_number ascending

#### Scenario: Address with no history
- **WHEN** `get_balance_history(1, "0xabc...")` is called for an address with no `balance_changes` rows
- **THEN** it returns `{:ok, []}`
