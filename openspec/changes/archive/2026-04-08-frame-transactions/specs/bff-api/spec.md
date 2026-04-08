## MODIFIED Requirements

### Requirement: Transaction detail aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/transactions/:hash` returning a single response that includes the transaction, its operations (with decoded summaries), token transfers (with resolved token names/symbols), event logs, cross-chain links, and for frame transactions: a `frames` array with per-frame mode, target, gas_limit, gas_used, status, and associated operations/logs grouped by frame_index.

#### Scenario: Frame transaction detail
- **WHEN** `GET /internal/chains/ethrex/transactions/0xabc...` is called for a frame transaction
- **THEN** the response contains `transaction` (with `payer`), `frames` array (with per-frame data), `operations` (with `frame_index`), `logs` (with `frame_index`), and `token_transfers` (with `frame_index`)

#### Scenario: Regular transaction detail unchanged
- **WHEN** `GET /internal/chains/ethereum/transactions/0xdef...` is called for a regular transaction
- **THEN** the response is unchanged — `frames` is an empty array or absent

### Requirement: Address overview aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/addresses/:hash` returning the address metadata (including balance), recent transactions (including transactions found via frame targets), and recent token transfers.

#### Scenario: Address overview includes frame-targeted transactions
- **WHEN** `GET /internal/chains/ethrex/addresses/0xUniswap` is called
- **THEN** the `recent_transactions` array includes frame transactions where 0xUniswap is a frame target
