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
The system SHALL expose `GET /internal/chains/:chain_slug/addresses/:hash` returning the address metadata, recent transactions (with operation summaries), and recent token transfers (with token metadata) in a single response.

#### Scenario: Address overview
- **WHEN** `GET /internal/chains/ethereum/addresses/0xabc...` is called
- **THEN** the response contains `address`, `recent_transactions` (last 25 with operation summaries), and `recent_token_transfers` (last 25 with token names)

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
