## ADDED Requirements

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
