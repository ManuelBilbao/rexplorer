## ADDED Requirements

### Requirement: Home page
The system SHALL provide a home page at `/:chain/` displaying the latest 10 blocks and latest 10 transactions for the selected chain. Data MUST be fetched from `GET /internal/chains/:chain_slug/home`. New blocks received via WebSocket MUST be prepended to the list in real-time.

#### Scenario: Home page loads
- **WHEN** the user navigates to `/ethereum/`
- **THEN** the page displays the latest blocks and transactions for Ethereum

#### Scenario: Real-time block update
- **WHEN** a new block is indexed while the user is viewing the home page
- **THEN** the new block appears at the top of the blocks list without page reload

### Requirement: Block list page
The system SHALL provide a block list page at `/:chain/blocks` displaying a paginated table of blocks with columns: block number, timestamp (TimeAgo), transaction count, gas used. Pagination MUST use the semantic `before` cursor from the API. A "Load more" button MUST fetch the next page.

#### Scenario: Browse blocks
- **WHEN** the user navigates to `/ethereum/blocks`
- **THEN** a table of the latest 25 blocks is displayed with a "Load more" button

#### Scenario: Load more blocks
- **WHEN** the user clicks "Load more"
- **THEN** the next 25 blocks are appended to the table

### Requirement: Block detail page
The system SHALL provide a block detail page at `/:chain/block/:number` displaying block header fields (number, hash, parent hash, timestamp, gas used/limit, base fee) and a list of transactions in the block.

#### Scenario: View block
- **WHEN** the user navigates to `/ethereum/block/20000000`
- **THEN** the block header and transaction list are displayed

### Requirement: Transaction detail page
The system SHALL provide a transaction detail page at `/:chain/tx/:hash` displaying the transaction summary, operations (with decoded summaries), token transfers, and event logs. Data MUST be fetched from the BFF aggregate endpoint `GET /internal/chains/:chain_slug/transactions/:hash`. The page MUST support a simple/advanced toggle: simple mode shows the human-readable summary and token transfers; advanced mode additionally shows raw calldata, log topics, and operation details.

#### Scenario: View transaction (simple mode)
- **WHEN** the user navigates to `/ethereum/tx/0xabc...`
- **THEN** the operation summary, status, token transfers, and cross-chain links (if any) are displayed

#### Scenario: Toggle to advanced mode
- **WHEN** the user clicks the "Advanced" toggle
- **THEN** raw calldata, event logs with topics, and full operation details are shown

#### Scenario: Cross-chain link displayed
- **WHEN** the transaction is part of a bridge deposit
- **THEN** a cross-chain status indicator shows the link type and current status

### Requirement: Address overview page
The system SHALL provide an address overview page at `/:chain/address/:hash` displaying address metadata (label, contract flag, first seen), recent transactions, and recent token transfers. Data MUST be fetched from the BFF aggregate endpoint `GET /internal/chains/:chain_slug/addresses/:hash`.

#### Scenario: View address
- **WHEN** the user navigates to `/ethereum/address/0xabc...`
- **THEN** the address metadata, recent transactions, and token transfers are displayed

#### Scenario: Contract address
- **WHEN** the address is a contract
- **THEN** a "Contract" badge is displayed alongside the address

### Requirement: Landing page / chain selector
The system SHALL provide a landing page at `/` that displays all enabled chains and allows the user to select one. Selecting a chain MUST navigate to `/:chain/`.

#### Scenario: Select chain
- **WHEN** the user visits `/` and clicks "Ethereum"
- **THEN** the app navigates to `/ethereum/`

### Requirement: 404 page
The system SHALL display a "not found" page when navigating to an unknown route or when a resource (block, transaction, address) doesn't exist.

#### Scenario: Unknown route
- **WHEN** the user navigates to `/ethereum/unknown-page`
- **THEN** a "Page not found" message is displayed
