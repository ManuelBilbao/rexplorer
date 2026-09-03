## MODIFIED Requirements

### Requirement: Transaction detail aggregate
The system SHALL expose `GET /internal/chains/:chain_slug/transactions/:hash` returning a single response that includes the transaction, its operations (with decoded summaries and their `op_extra`), token transfers (with resolved token names/symbols), event logs, and any cross-chain links. This avoids multiple round-trips from the UI. For an ERC-4337 bundle the response MUST carry enough per-operation detail — userOpHash, UserOperation index, sender, paymaster, outcome and EntryPoint — for the client to group operations into UserOperations without a second request.

#### Scenario: Full transaction detail
- **WHEN** `GET /internal/chains/ethereum/transactions/0xabc...` is called
- **THEN** the response contains `transaction`, `operations` (each with `op_extra`), `token_transfers` (with token metadata), `logs`, and `cross_chain_links` all in one payload

#### Scenario: Transaction with cross-chain link
- **WHEN** a transaction is part of a bridge deposit
- **THEN** the `cross_chain_links` array includes the link with source/destination chain info and current status

#### Scenario: Frame transaction detail
- **WHEN** `GET /internal/chains/ethrex/transactions/0xabc...` is called for a frame transaction
- **THEN** the response contains `transaction` (with `payer`), `frames` array (with per-frame data), `operations` (with `frame_index`), `logs` (with `frame_index`), and `token_transfers` (with `frame_index`)

#### Scenario: Bundle transaction detail
- **WHEN** the requested transaction is an ERC-4337 bundle
- **THEN** every `user_operation` entry in `operations` carries its `user_op_hash`, `user_op_index`, `entry_point`, `entry_point_version`, `paymaster` when sponsored, `factory` when deploying, and its own success flag

#### Scenario: Non-AA transaction
- **WHEN** the requested transaction is an ordinary call
- **THEN** its operations carry an empty `op_extra` and the response shape is otherwise unchanged

### Requirement: Search endpoint
The system SHALL expose `GET /internal/search?q=<query>&chain=<optional_slug>` that identifies the query type (transaction hash, userOpHash, block number, address) and returns matching results. If the query matches exactly one entity, the response MUST include a `redirect` hint.

#### Scenario: Search by transaction hash
- **WHEN** `GET /internal/search?q=0xabc...` is called with a 66-char hex string
- **THEN** the response identifies it as a transaction hash and returns `{"type": "transaction", "redirect": "/ethereum/tx/0xabc..."}`

#### Scenario: Search by block number
- **WHEN** `GET /internal/search?q=20000000` is called with a numeric string
- **THEN** the response identifies it as a block number and returns matching blocks across chains

#### Scenario: Search by address
- **WHEN** `GET /internal/search?q=0xabc...` is called with a 42-char hex string
- **THEN** the response identifies it as an address and returns matching address records across chains

#### Scenario: Search by userOpHash
- **WHEN** a 66-char hex string matches no transaction but matches a stored userOpHash
- **THEN** the response identifies it as a user operation and redirects to the parent transaction, anchored to that UserOperation
