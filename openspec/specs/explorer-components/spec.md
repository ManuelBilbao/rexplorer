## ADDED Requirements

### Requirement: AddressDisplay component
The system SHALL provide an `AddressDisplay` component that renders a blockchain address with: truncation (showing first 6 and last 4 characters by default), a copy-to-clipboard button, an optional label (ENS name or known protocol name), and a link to the address page. If a label is present, it MUST be shown instead of the truncated hash, with the full hash available on hover.

#### Scenario: Address with label
- **WHEN** `<AddressDisplay address="0x7a25..." label="vitalik.eth" chain="ethereum" />` is rendered
- **THEN** "vitalik.eth" is displayed as a link with the full address visible on hover/tooltip

#### Scenario: Address without label
- **WHEN** `<AddressDisplay address="0x7a250d5630b4cf539739df2c5dacb4c659f2488d" chain="ethereum" />` is rendered
- **THEN** "0x7a25...488d" is displayed as a link with a copy button

### Requirement: TxHash component
The system SHALL provide a `TxHash` component that renders a transaction hash with truncation and a copy button. It MUST link to the transaction detail page.

#### Scenario: Transaction hash display
- **WHEN** `<TxHash hash="0xabc...def" chain="ethereum" />` is rendered
- **THEN** the truncated hash is displayed as a clickable link to the transaction page

### Requirement: TokenAmount component
The system SHALL provide a `TokenAmount` component that formats a raw token amount with its symbol. It MUST handle decimal conversion (dividing by 10^decimals) and display a human-readable number.

#### Scenario: ETH amount
- **WHEN** `<TokenAmount value="1000000000000000000" symbol="ETH" decimals={18} />` is rendered
- **THEN** "1.0 ETH" is displayed

#### Scenario: Large token amount
- **WHEN** a value of 25000 USDC (6 decimals) is rendered
- **THEN** "25,000 USDC" is displayed with thousand separators

### Requirement: BlockNumber component
The system SHALL provide a `BlockNumber` component that renders a block number as a link to the block detail page. It MUST format the number with thousand separators.

#### Scenario: Block number display
- **WHEN** `<BlockNumber number={20000000} chain="ethereum" />` is rendered
- **THEN** "20,000,000" is displayed as a clickable link

### Requirement: TimeAgo component
The system SHALL provide a `TimeAgo` component that displays a relative timestamp (e.g., "2 min ago") with the absolute datetime available on hover/tooltip. It MUST update periodically without page reload. Pages MUST use the TimeAgo component instead of the `timeAgo()` utility function for rendered timestamps.

#### Scenario: Recent timestamp
- **WHEN** a timestamp from 3 minutes ago is rendered
- **THEN** "3 min ago" is displayed with the full datetime on hover

#### Scenario: Auto-refresh
- **WHEN** the component has been mounted for 60 seconds
- **THEN** the displayed relative time has updated at least once without page reload

### Requirement: StatusBadge component
The system SHALL provide a `StatusBadge` component that renders transaction status as a colored badge: green "Success" for `status: true`, red "Failed" for `status: false`, gray "Pending" for `status: null`. StatusBadge MUST use the `Badge` UI component internally, mapping status values to Badge variants (`green`, `red`, `gray`).

#### Scenario: Successful transaction
- **WHEN** `<StatusBadge status={true} />` is rendered
- **THEN** a green "Success" Badge is displayed

#### Scenario: Failed transaction
- **WHEN** `<StatusBadge status={false} />` is rendered
- **THEN** a red "Failed" Badge is displayed

#### Scenario: Pending transaction
- **WHEN** `<StatusBadge status={null} />` is rendered
- **THEN** a gray "Pending" Badge is displayed

### Requirement: ChainBadge component
The system SHALL provide a `ChainBadge` component that displays a chain's name with a colored indicator. The chain color map MUST include all supported chains: ethereum, polygon, arbitrum, optimism, base, avalanche, bsc, fantom, gnosis, zksync, bnb. Unsupported chains MUST fall back to a default gray color. ChainBadge MUST use the `Badge` UI component internally.

#### Scenario: Chain badge
- **WHEN** `<ChainBadge chain="ethereum" />` is rendered
- **THEN** an "Ethereum" Badge with the Ethereum-associated color dot is displayed

#### Scenario: Unknown chain fallback
- **WHEN** `<ChainBadge chain="unknown-chain" />` is rendered
- **THEN** a gray Badge with "unknown-chain" text is displayed

### Requirement: CopyButton component
The system SHALL provide a `CopyButton` component that copies a value to the clipboard on click and shows a brief "Copied!" confirmation.

#### Scenario: Copy to clipboard
- **WHEN** the user clicks a CopyButton
- **THEN** the value is copied and a "Copied!" indicator appears briefly

### Requirement: SearchBar component
The system SHALL provide a `SearchBar` component that accepts a query string and calls the `/internal/search` endpoint. It MUST display a loading state during search and navigate to the result if a single match is found (using the redirect hint from the API).

#### Scenario: Search by tx hash
- **WHEN** the user pastes a transaction hash and presses Enter
- **THEN** the app navigates to the transaction detail page for that hash
