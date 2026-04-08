## ADDED Requirements

### Requirement: Transaction detail aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/transactions/:hash` returning a single response that includes the transaction, its operations (with decoded summaries), token transfers (with resolved token names/symbols), event logs, and any cross-chain links. This avoids multiple round-trips from the UI.

#### Scenario: Full transaction detail
- **WHEN** `GET /internal/chains/ethereum/transactions/0xabc...` is called
- **THEN** the response contains `transaction`, `operations`, `token_transfers` (with token metadata), `logs`, and `cross_chain_links` all in one payload

#### Scenario: Transaction with cross-chain link
- **WHEN** a transaction is part of a bridge deposit
- **THEN** the `cross_chain_links` array includes the link with source/destination chain info and current status

### Requirement: Address overview aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/addresses/:hash` returning the address metadata (including current native-token balance as `balance_wei`), recent transactions (with operation summaries), and recent token transfers (with token metadata) in a single response.

#### Scenario: Address overview with balance
- **WHEN** `GET /internal/chains/ethereum/addresses/0xabc...` is called
- **THEN** the response contains `address` (with `balance_wei` field), `recent_transactions` (last 25 with operation summaries), and `recent_token_transfers` (last 25 with token names)

#### Scenario: Address overview with no balance data
- **WHEN** `GET /internal/chains/ethereum/addresses/0xabc...` is called for an address with no balance data
- **THEN** the `address.balance_wei` field is `null`

### Requirement: Balance history endpoint
The system SHALL expose `GET /internal/chains/:chain_slug/addresses/:hash/balance-history` returning a time-ordered list of balance data points suitable for rendering a chart. The endpoint MUST support cursor-based pagination via `before` (block_number) and `limit` query parameters.

#### Scenario: Fetch balance history
- **WHEN** `GET /internal/chains/ethereum/addresses/0xabc.../balance-history` is called
- **THEN** the response contains `{"data": [...], "next_cursor": <block_number|null>}` with entries ordered by block_number ascending

#### Scenario: Paginated balance history
- **WHEN** `GET /internal/chains/ethereum/addresses/0xabc.../balance-history?before=1000&limit=50` is called
- **THEN** the response contains at most 50 entries with `block_number < 1000`

#### Scenario: Empty balance history
- **WHEN** the address has no balance_changes rows
- **THEN** the response is `{"data": [], "next_cursor": null}`

#### Scenario: Unknown address returns 404
- **WHEN** the address does not exist in the database
- **THEN** the endpoint returns HTTP 404

### Requirement: Home page data aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/home` returning the latest blocks (with transaction counts) and latest transactions for the chain's home page view.

#### Scenario: Home page data
- **WHEN** `GET /internal/chains/ethereum/home` is called
- **THEN** the response contains `latest_blocks` (last 10) and `latest_transactions` (last 10)

### Requirement: Search endpoint
The system SHALL expose `GET /internal/search?q=<query>&chain=<optional_slug>` that identifies the query type (transaction hash, block number, address) and returns matching results. If the query matches exactly one entity, the response MUST include a `redirect` hint.

#### Scenario: Search by transaction hash
- **WHEN** `GET /internal/search?q=0xabc...` is called with a 66-char hex string
- **THEN** the response identifies it as a transaction hash and returns `{"type": "transaction", "redirect": "/ethereum/tx/0xabc..."}`

#### Scenario: Search by block number
- **WHEN** `GET /internal/search?q=20000000` is called with a numeric string
- **THEN** the response identifies it as a block number and returns matching blocks across chains

#### Scenario: Search by address
- **WHEN** `GET /internal/search?q=0xabc...` is called with a 42-char hex string
- **THEN** the response identifies it as an address and returns matching address records across chains

### Requirement: Internal transactions endpoint
The BFF SHALL expose `GET /internal/chains/:chain_slug/addresses/:hash/internal-transactions` returning paginated internal transactions for an address. Each entry MUST include `transaction_hash`, `block_number`, `from_address`, `to_address`, `value` (string-encoded wei), `call_type`, and `trace_address`.

#### Scenario: Fetch internal transactions
- **WHEN** `GET /internal/chains/ethrex-65536999/addresses/0xABC/internal-transactions` is called
- **THEN** the response contains `{"data": [...], "next_cursor": ...}` with internal transaction entries ordered by block_number descending

#### Scenario: Pagination
- **WHEN** `GET .../internal-transactions?before=1000&limit=25` is called
- **THEN** the response contains at most 25 entries with `block_number < 1000`

#### Scenario: No internal transactions
- **WHEN** the address has no internal transactions
- **THEN** the response is `{"data": [], "next_cursor": null}`

### Requirement: Public API internal transactions endpoint
The public API SHALL expose `GET /api/v1/chains/:chain_slug/addresses/:hash/internal-transactions` with the same response shape as the BFF endpoint.

#### Scenario: Public API internal transactions
- **WHEN** `GET /api/v1/chains/ethrex-65536999/addresses/0xABC/internal-transactions` is called
- **THEN** the response contains the same data format as the BFF endpoint
