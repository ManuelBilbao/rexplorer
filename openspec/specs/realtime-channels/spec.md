## ADDED Requirements

### Requirement: New blocks channel
The system SHALL provide a Phoenix Channel topic `blocks:<chain_slug>` that broadcasts new block events whenever a block is indexed. Each broadcast MUST include block number, hash, timestamp, transaction_count, and gas_used.

#### Scenario: Subscribe to new Ethereum blocks
- **WHEN** a client joins `blocks:ethereum`
- **THEN** they receive a `new_block` event each time a new Ethereum block is indexed

#### Scenario: Multi-chain subscription
- **WHEN** a client joins `blocks:optimism` and `blocks:ethereum`
- **THEN** they receive block events from both chains independently

### Requirement: Address activity channel
The system SHALL provide a Phoenix Channel topic `address:<chain_slug>:<address_hash>` that broadcasts events when the address is involved in a new transaction (as sender or recipient) or receives a token transfer.

#### Scenario: Watch address for transactions
- **WHEN** a client joins `address:ethereum:0xabc...` and a new transaction involving that address is indexed
- **THEN** the client receives a `new_transaction` event with the transaction summary

#### Scenario: Watch address for token transfers
- **WHEN** a client joins `address:ethereum:0xabc...` and a new ERC-20 transfer to that address is indexed
- **THEN** the client receives a `new_token_transfer` event with transfer details

### Requirement: Channel authentication
Channels MUST be accessible without authentication for v1. The socket endpoint MUST accept connections at `/socket` with a transport of WebSocket.

#### Scenario: Anonymous connection
- **WHEN** a client connects to `/socket` without credentials
- **THEN** the connection is accepted and the client can join any public topic
