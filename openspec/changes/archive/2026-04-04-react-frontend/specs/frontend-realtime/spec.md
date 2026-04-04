## ADDED Requirements

### Requirement: Phoenix Socket connection
The system SHALL establish a WebSocket connection to the Phoenix socket at `/socket` on application mount. The connection MUST reconnect automatically on disconnect.

#### Scenario: WebSocket connects on app load
- **WHEN** the React app mounts
- **THEN** a WebSocket connection to `/socket` is established

#### Scenario: Automatic reconnection
- **WHEN** the WebSocket connection drops
- **THEN** the client reconnects automatically with exponential backoff

### Requirement: Block subscription hook
The system SHALL provide a `useBlockSubscription(chainSlug)` hook that joins the `blocks:<chainSlug>` channel and invokes a callback when a `new_block` event is received.

#### Scenario: Receive new block event
- **WHEN** the hook is active for "ethereum" and a new block is indexed
- **THEN** the callback receives the block summary (number, hash, timestamp, tx count)

#### Scenario: Channel switches on chain change
- **WHEN** the user switches from Ethereum to Optimism
- **THEN** the hook leaves the `blocks:ethereum` channel and joins `blocks:optimism`

### Requirement: Address activity subscription hook
The system SHALL provide a `useAddressSubscription(chainSlug, addressHash)` hook that joins the `address:<chainSlug>:<addressHash>` channel and invokes callbacks for `new_transaction` and `new_token_transfer` events.

#### Scenario: Receive transaction event for watched address
- **WHEN** the user is viewing an address page and a new transaction involving that address is indexed
- **THEN** a toast notification appears and the transaction list can be refreshed
