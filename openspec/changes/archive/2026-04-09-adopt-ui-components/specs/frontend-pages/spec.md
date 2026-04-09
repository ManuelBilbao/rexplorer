## MODIFIED Requirements

### Requirement: Block list page
The system SHALL provide a block list page at `/:chain/blocks` displaying a paginated table of blocks using the `DataTable` component with columns: block number (via `BlockNumber` component), timestamp (via `TimeAgo` component), transaction count, gas used. Pagination MUST use the `DataTable`'s `onLoadMore`/`hasMore` props. Loading state MUST use `DataTable`'s built-in skeleton loading.

#### Scenario: Browse blocks
- **WHEN** the user navigates to `/ethereum/blocks`
- **THEN** a DataTable of the latest 25 blocks is displayed with a "Load more" button

#### Scenario: Loading state
- **WHEN** the block list is loading
- **THEN** the DataTable displays skeleton rows (not hand-rolled animate-pulse divs)

### Requirement: Block detail page
The system SHALL provide a block detail page at `/:chain/block/:number` displaying block header fields and a list of transactions using the `DataTable` component. Loading state MUST use the `Skeleton` component. Address cells MUST use `AddressDisplay`. Timestamps MUST use `TimeAgo`.

#### Scenario: View block
- **WHEN** the user navigates to `/ethereum/block/20000000`
- **THEN** the block header and transaction DataTable are displayed

#### Scenario: Loading state
- **WHEN** the block detail is loading
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

### Requirement: Transaction detail page
The system SHALL provide a transaction detail page at `/:chain/tx/:hash`. Status MUST be rendered via `StatusBadge`. Chain MUST be rendered via `ChainBadge` (not a local function). Block number MUST use `BlockNumber`. Addresses MUST use `AddressDisplay`. Timestamps MUST use `TimeAgo`. The simple/advanced toggle buttons MUST use the `Button` component. Loading state MUST use `Skeleton`.

#### Scenario: View transaction (simple mode)
- **WHEN** the user navigates to `/ethereum/tx/0xabc...`
- **THEN** status is shown via StatusBadge, chain via ChainBadge, addresses via AddressDisplay

#### Scenario: Loading state
- **WHEN** the transaction detail is loading
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

#### Scenario: No local component re-definitions
- **WHEN** the TxDetailPage module is inspected
- **THEN** there are no local ChainBadge or StatusBadge function definitions — only imports from components/explorer/

### Requirement: Address overview page
The address page (`/:chain/address/:hash`) SHALL use shared components throughout. Status badges MUST use `StatusBadge`. "Load more" buttons MUST use `Button`. Loading states MUST use `Skeleton`. Address rendering MUST use `AddressDisplay`. Timestamps MUST use `TimeAgo`. Token amounts MUST use `TokenAmount` where applicable. The "Contract" label MUST use `Badge`.

#### Scenario: View address with transactions
- **WHEN** the user navigates to `/ethereum/address/0xabc...`
- **THEN** transaction statuses use StatusBadge, addresses use AddressDisplay, timestamps use TimeAgo

#### Scenario: Load more uses Button component
- **WHEN** the "Load more" button is rendered on any tab
- **THEN** it uses the shared Button component, not a raw `<button>` element

#### Scenario: Loading state
- **WHEN** any tab is loading data
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

### Requirement: Home page
The home page MUST use `Skeleton` for loading states, `BlockNumber` for block links, and `TimeAgo` for timestamps. The status dot indicator pattern (colored dots for tx status in compact lists) MAY remain as-is since it serves a different visual purpose than StatusBadge.

#### Scenario: Loading state
- **WHEN** the home page is loading
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

#### Scenario: Block numbers are linked
- **WHEN** a block number is displayed in the latest blocks list
- **THEN** it uses the BlockNumber component

## REMOVED Requirements

### Requirement: Design preview page
**Reason**: The DesignPreview page (`/design` route) was a scaffolding artifact used for palette exploration during initial development. Its purpose is complete — the color system is established via Tailwind design tokens. The page uses zero shared components, zero Tailwind classes, and 100% inline styles with hardcoded mock data.
**Migration**: No migration needed. Palette history is preserved in git. Remove `DesignPreview.tsx` and its route from `App.tsx`.
