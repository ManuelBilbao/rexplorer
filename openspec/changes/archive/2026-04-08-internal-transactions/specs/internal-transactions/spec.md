## ADDED Requirements

### Requirement: Internal transactions table
The system SHALL maintain an `internal_transactions` table storing value-transferring trace entries from block execution. Each entry MUST be uniquely identified by `(chain_id, block_number, transaction_index, trace_index)` and MUST store: `from_address`, `to_address` (nullable for selfdestructs without recipient), `value` (numeric), `call_type` (enum: `call`, `create`, `create2`, `selfdestruct`), `trace_address` (integer array representing the path in the call tree), `transaction_hash`, `input_prefix` (first 4 bytes of calldata, nullable), and `error` (nullable).

#### Scenario: Deposit internal transaction stored
- **WHEN** block N contains a deposit where system address `0x...ffff` calls the bridge which transfers 1 ETH to recipient `0xABC`
- **THEN** an `internal_transactions` row is inserted with `from_address = "0x...ffff"`, `to_address = "0xABC"`, `value = 1000000000000000000`, `call_type = "call"`

#### Scenario: Zero-value call excluded
- **WHEN** block N contains a trace with a zero-value CALL from contract A to contract B
- **THEN** no `internal_transactions` row is inserted for that trace entry

#### Scenario: CREATE stored
- **WHEN** block N contains a trace where contract A creates contract B via CREATE
- **THEN** an `internal_transactions` row is inserted with `call_type = "create"` and `to_address` set to the created contract address

#### Scenario: SELFDESTRUCT stored
- **WHEN** block N contains a trace where contract A self-destructs, sending remaining balance to address B
- **THEN** an `internal_transactions` row is inserted with `call_type = "selfdestruct"`, `from_address = A`, `to_address = B`

### Requirement: Trace flattening to structured entries
The system SHALL provide a function that converts nested `callTracer` output into a flat list of structured internal transaction entries. Each entry MUST include a `trace_index` (sequential integer) and `trace_address` (integer array path in the call tree). Only entries where `value > 0` OR `type` is `CREATE`/`CREATE2`/`SELFDESTRUCT` SHALL be included.

#### Scenario: Nested calls flattened with trace addresses
- **WHEN** a trace shows A → B → C → D (nested calls, all with value)
- **THEN** the flattener produces entries with `trace_address` values `[0]`, `[0, 0]`, `[0, 0, 0]` respectively

#### Scenario: Mixed value and zero-value calls
- **WHEN** a trace shows A calls B (value=1), B calls C (value=0), B calls D (value=2)
- **THEN** only the A→B and B→D entries are returned (C is zero-value call, excluded)

### Requirement: Internal transactions query by address
The system SHALL provide `Rexplorer.InternalTransactions.list_by_address(chain_id, hash, opts)` returning paginated internal transactions where the address is either `from_address` or `to_address`. The function MUST use two separate indexed queries (one per address column) merged and deduplicated for performance.

#### Scenario: Query internal transactions for deposit recipient
- **WHEN** `list_by_address(chain_id, "0xABC")` is called for an address that received deposits via internal calls
- **THEN** the deposit internal transactions are returned with `to_address = "0xABC"`

#### Scenario: Cursor-based pagination
- **WHEN** `list_by_address(chain_id, "0xABC", before: 1000, limit: 25)` is called
- **THEN** at most 25 entries with `block_number < 1000` are returned, ordered by block_number descending

#### Scenario: No internal transactions
- **WHEN** `list_by_address(chain_id, "0xABC")` is called for an address with no internal transactions
- **THEN** it returns `{:ok, [], nil}`
