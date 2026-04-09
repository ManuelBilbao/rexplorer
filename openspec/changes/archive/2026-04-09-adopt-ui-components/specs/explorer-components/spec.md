## MODIFIED Requirements

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

### Requirement: TimeAgo component
The system SHALL provide a `TimeAgo` component that displays a relative timestamp (e.g., "2 min ago") with the absolute datetime available on hover/tooltip. It MUST update periodically without page reload. Pages MUST use the TimeAgo component instead of the `timeAgo()` utility function for rendered timestamps.

#### Scenario: Recent timestamp
- **WHEN** a timestamp from 3 minutes ago is rendered
- **THEN** "3 min ago" is displayed with the full datetime on hover

#### Scenario: Auto-refresh
- **WHEN** the component has been mounted for 60 seconds
- **THEN** the displayed relative time has updated at least once without page reload
