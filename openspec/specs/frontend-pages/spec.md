## Purpose

The pages of the explorer, and the shared components each one is required to render with.

## Requirements

### Requirement: Home page
The home page MUST use `Skeleton` for loading states, `BlockNumber` for block links, and `TimeAgo` for timestamps. The status dot indicator pattern (colored dots for tx status in compact lists) MAY remain as-is since it serves a different visual purpose than StatusBadge.

#### Scenario: Loading state
- **WHEN** the home page is loading
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

#### Scenario: Block numbers are linked
- **WHEN** a block number is displayed in the latest blocks list
- **THEN** it uses the BlockNumber component

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

When the transaction is an ERC-4337 bundle, the page MUST present it as the bundle it is: a UserOperations section listing each UserOperation in bundle order, each showing its smart account sender, its own success state, a paymaster badge when sponsored, a deployment badge when it created its account, and the decoded actions it performed. The story hero MUST describe the bundle from the user's point of view rather than narrating the bundler's call, and a bundle of one UserOperation MUST read as that single operation's story. The userOpHash MUST be visible and copyable in the section, so a user arriving from a userOpHash search can confirm which operation they were looking for.

#### Scenario: View transaction (simple mode)
- **WHEN** the user navigates to `/ethereum/tx/0xabc...`
- **THEN** status is shown via StatusBadge, chain via ChainBadge, addresses via AddressDisplay

#### Scenario: Loading state
- **WHEN** the transaction detail is loading
- **THEN** Skeleton components are displayed (not hand-rolled animate-pulse divs)

#### Scenario: No local component re-definitions
- **WHEN** the TxDetailPage module is inspected
- **THEN** there are no local ChainBadge or StatusBadge function definitions — only imports from components/explorer/

#### Scenario: View an AA bundle
- **WHEN** the user opens a transaction that bundles three UserOperations
- **THEN** three UserOperation entries are listed, each with its own sender, outcome and decoded actions

#### Scenario: Sponsored operation is legible
- **WHEN** a UserOperation was paid for by a paymaster
- **THEN** the entry shows a paymaster badge and the sponsor's address, so a regular user can see they did not pay gas

#### Scenario: One operation failed in a successful bundle
- **WHEN** the transaction succeeded but one UserOperation reverted
- **THEN** that entry is marked failed while the others are marked successful, and the page does not claim the whole transaction failed

#### Scenario: Batched UserOperation
- **WHEN** a single UserOperation performed several actions
- **THEN** they appear as multiple actions grouped under that one UserOperation, not as separate UserOperations

#### Scenario: Arriving from a userOpHash search
- **WHEN** the user searches a userOpHash and lands on the transaction page
- **THEN** the matching UserOperation is identifiable on the page by its visible hash

#### Scenario: Advanced mode
- **WHEN** a developer switches to advanced mode on a bundle
- **THEN** the raw operations list and the decoded EntryPoint event logs remain available alongside the UserOperations section

#### Scenario: Non-AA transaction unaffected
- **WHEN** the transaction is not a bundle
- **THEN** no UserOperations section is rendered and the page behaves exactly as before

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

<!-- Removed by change: adopt-ui-components -->
<!-- Requirement: Design preview page — The DesignPreview page (`/design` route) was a scaffolding artifact used for palette exploration during initial development. Its purpose is complete — the color system is established via Tailwind design tokens. The page uses zero shared components, zero Tailwind classes, and 100% inline styles with hardcoded mock data. Migration: No migration needed. Palette history is preserved in git. Remove `DesignPreview.tsx` and its route from `App.tsx`. -->
