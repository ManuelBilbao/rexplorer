## ADDED Requirements

### Requirement: Blocks endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/blocks` returning a paginated list of blocks and `GET /api/v1/chains/:chain_slug/blocks/:number` returning a single block by number. Both MUST include block header fields (number, hash, timestamp, gas_used, gas_limit, base_fee_per_gas, transaction_count). The list endpoint MUST support cursor-based pagination using block number as cursor.

#### Scenario: List recent blocks
- **WHEN** `GET /api/v1/chains/ethereum/blocks` is called without pagination params
- **THEN** the response contains the 25 most recent blocks in descending order with a `next_cursor` for pagination

#### Scenario: Get block by number
- **WHEN** `GET /api/v1/chains/ethereum/blocks/20000000` is called
- **THEN** the response contains the block with all header fields and a `transaction_count` field

#### Scenario: Block not found
- **WHEN** `GET /api/v1/chains/ethereum/blocks/999999999` is called for a non-existent block
- **THEN** the response returns HTTP 404 with `{"error": "not_found"}`

### Requirement: Transactions endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/transactions` (paginated list with optional address filter) and `GET /api/v1/chains/:chain_slug/transactions/:hash` (single transaction). Transaction responses MUST include hash, from_address, to_address, value, gas_price, gas_used, status, block_number, and transaction_index.

#### Scenario: Get transaction by hash
- **WHEN** `GET /api/v1/chains/ethereum/transactions/0xabc...` is called
- **THEN** the response contains the transaction with all fields

#### Scenario: List transactions for an address
- **WHEN** `GET /api/v1/chains/ethereum/transactions?address=0xabc...` is called
- **THEN** the response contains paginated transactions where the address is either sender or recipient

#### Scenario: Transaction not found
- **WHEN** a non-existent transaction hash is queried
- **THEN** the response returns HTTP 404

### Requirement: Operations endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/transactions/:hash/operations` returning operations (user intents) for a transaction. Each operation MUST include operation_type, operation_index, from_address, to_address, value, and decoded_summary (if available).

#### Scenario: List operations for a transaction
- **WHEN** `GET /api/v1/chains/ethereum/transactions/0xabc.../operations` is called
- **THEN** the response contains all operations ordered by operation_index

### Requirement: Addresses endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/addresses/:hash` returning address metadata (is_contract, label, first_seen_at) and `GET /api/v1/chains/:chain_slug/addresses/:hash/token-transfers` returning paginated token transfers for the address.

#### Scenario: Get address info
- **WHEN** `GET /api/v1/chains/ethereum/addresses/0xabc...` is called
- **THEN** the response contains the address with is_contract flag, label, and first_seen_at

#### Scenario: Address not found
- **WHEN** a never-seen address is queried
- **THEN** the response returns HTTP 404

### Requirement: Token transfers endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/addresses/:hash/token-transfers` returning paginated token transfers involving the address (as sender or recipient). Each transfer MUST include from_address, to_address, token_contract_address, amount, token_type, and transaction hash.

#### Scenario: List token transfers for address
- **WHEN** `GET /api/v1/chains/ethereum/addresses/0xabc.../token-transfers` is called
- **THEN** the response contains paginated token transfers in descending order

### Requirement: Chains endpoint
The system SHALL expose `GET /api/v1/chains` returning all enabled chains and `GET /api/v1/chains/:slug` returning a single chain's details. Chain responses MUST include chain_id, name, chain_type, native_token_symbol, and explorer_slug.

#### Scenario: List all chains
- **WHEN** `GET /api/v1/chains` is called
- **THEN** the response contains all enabled chains

### Requirement: Consistent error responses
All API error responses MUST follow a consistent format: `{"error": "<code>", "message": "<human-readable description>"}`. HTTP status codes MUST be used correctly: 404 for not found, 400 for bad request, 422 for validation errors, 500 for internal errors.

#### Scenario: Invalid chain slug
- **WHEN** `GET /api/v1/chains/nonexistent/blocks` is called
- **THEN** the response returns HTTP 404 with `{"error": "not_found", "message": "Chain not found"}`

### Requirement: Cursor-based pagination
All list endpoints MUST support cursor-based pagination with `cursor` and `limit` query parameters. The default limit MUST be 25 and maximum MUST be 100. Responses MUST include `next_cursor` (null if no more results) and `total_count` (when feasible).

#### Scenario: Paginate through blocks
- **WHEN** `GET /api/v1/chains/ethereum/blocks?limit=10` is called
- **THEN** the response contains 10 blocks and a `next_cursor` value
- **AND** calling with `?cursor=<next_cursor>&limit=10` returns the next 10 blocks
