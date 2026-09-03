## MODIFIED Requirements

### Requirement: Operations endpoint
The system SHALL expose `GET /api/v1/chains/:chain_slug/transactions/:hash/operations` returning operations (user intents) for a transaction. Each operation MUST include operation_type, operation_index, from_address, to_address, value, decoded_summary (if available), and the operation's structured extras: for ERC-4337 operations, `user_op_hash`, `user_op_index`, `entry_point`, `entry_point_version`, `paymaster`, `factory`, `success` and `actual_gas_cost`. The field names and shape MUST be documented in the OpenAPI spec, since this is the versioned public surface.

#### Scenario: List operations for a transaction
- **WHEN** `GET /api/v1/chains/ethereum/transactions/0xabc.../operations` is called
- **THEN** the response contains all operations ordered by operation_index

#### Scenario: Bundle operations for an integrator
- **WHEN** the transaction is an ERC-4337 bundle
- **THEN** each returned operation carries its UserOperation hash, index and paymaster, so a wallet or indexer can reconstruct the bundle without parsing calldata

#### Scenario: Documented in OpenAPI
- **WHEN** the OpenAPI document is fetched
- **THEN** the operation schema describes the ERC-4337 fields and marks them optional

#### Scenario: Non-AA operations unchanged
- **WHEN** the transaction is an ordinary call
- **THEN** the operation is returned exactly as before, with no ERC-4337 fields populated
