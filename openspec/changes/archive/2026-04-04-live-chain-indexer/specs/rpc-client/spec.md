## ADDED Requirements

### Requirement: JSON-RPC client for Ethereum-compatible nodes
The system SHALL provide a stateless module `Rexplorer.RPC.Client` that communicates with Ethereum-compatible JSON-RPC endpoints over HTTP. The client MUST support batch and individual JSON-RPC calls and handle standard error responses.

#### Scenario: Successful single RPC call
- **WHEN** `Rexplorer.RPC.Client.call(url, "eth_blockNumber", [])` is invoked
- **THEN** it returns `{:ok, result}` with the decoded JSON-RPC result field

#### Scenario: RPC call returns an error
- **WHEN** the RPC node returns a JSON-RPC error response (e.g., method not found)
- **THEN** the client returns `{:error, %{code: integer, message: string}}`

#### Scenario: Network failure
- **WHEN** the HTTP request to the RPC node fails (timeout, connection refused)
- **THEN** the client returns `{:error, reason}` without crashing

### Requirement: Block fetching
The system SHALL provide `Rexplorer.RPC.Client.get_block/3` that fetches a block by number from a given RPC endpoint. The function MUST request full transaction objects (not just hashes). Block numbers MUST be sent as hex-encoded strings per the JSON-RPC spec.

#### Scenario: Fetch block with transactions
- **WHEN** `get_block(url, block_number, full_transactions: true)` is called
- **THEN** it returns `{:ok, block_map}` where `block_map` contains the block header fields and a `"transactions"` list with full transaction objects

#### Scenario: Fetch non-existent block
- **WHEN** `get_block(url, block_number)` is called for a block that doesn't exist yet
- **THEN** it returns `{:ok, nil}`

### Requirement: Block receipts fetching
The system SHALL provide `Rexplorer.RPC.Client.get_block_receipts/2` that fetches all transaction receipts for a given block number in a single RPC call using `eth_getBlockReceipts`.

#### Scenario: Fetch all receipts for a block
- **WHEN** `get_block_receipts(url, block_number)` is called
- **THEN** it returns `{:ok, [receipt_map, ...]}` with one receipt per transaction in the block, each containing `status`, `gasUsed`, `logs`, and `transactionHash`

### Requirement: Latest block number
The system SHALL provide `Rexplorer.RPC.Client.get_latest_block_number/1` that returns the current head block number of the chain.

#### Scenario: Query chain head
- **WHEN** `get_latest_block_number(url)` is called
- **THEN** it returns `{:ok, integer}` with the block number decoded from hex to integer
