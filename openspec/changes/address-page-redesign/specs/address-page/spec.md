## ADDED Requirements

### Requirement: Address stat cards
The address page SHALL display three stat cards at the top: Balance (formatted native token amount with symbol), Last Active (relative time from most recent transaction), and First Seen (relative time from `first_seen_at`).

#### Scenario: Address with balance and transactions
- **WHEN** the user views an address page for an address with `balance_wei = "2534891000000000000"` and recent transactions
- **THEN** the stat cards show "2.534891 ETH" for Balance, a relative time (e.g., "2h ago") for Last Active, and a relative time for First Seen

#### Scenario: Address with no balance data
- **WHEN** the user views an address page where `balance_wei` is null
- **THEN** the Balance stat card shows "—" or "0"

#### Scenario: Address with no transactions
- **WHEN** the user views an address page with no recent transactions
- **THEN** the Last Active stat card shows "No activity" or falls back to the First Seen value

### Requirement: Balance history chart
The address page SHALL display an area chart showing the native token balance over time. The chart MUST be rendered as an inline SVG with no external chart library dependency. The chart data MUST be fetched from the balance history BFF endpoint.

#### Scenario: Address with balance history
- **WHEN** the user views an address page for an address with 10+ balance change data points
- **THEN** an area chart is rendered showing balance on the Y axis and time on the X axis

#### Scenario: Address with no balance history
- **WHEN** the user views an address page for an address with no balance_changes rows
- **THEN** the chart section shows an empty state message instead of a degenerate chart

#### Scenario: Chart loading state
- **WHEN** the balance history data is still loading
- **THEN** a skeleton placeholder is shown in the chart area

### Requirement: Tabbed transaction and token transfer sections
The address page SHALL organize transactions and token transfers into a tabbed layout using the existing `Tabs` UI component.

#### Scenario: Default tab
- **WHEN** the user views the address page
- **THEN** the Transactions tab is active by default

#### Scenario: Switch to token transfers
- **WHEN** the user clicks the "Token Transfers" tab
- **THEN** the token transfer list is shown and the transactions list is hidden

### Requirement: Transaction list pagination
The transactions tab SHALL support cursor-based pagination with a "Load more" button. Initial data comes from the address overview response. Subsequent pages MUST be fetched from the paginated transactions API endpoint.

#### Scenario: More transactions available
- **WHEN** the address has more than 25 transactions
- **THEN** a "Load more" button appears below the transaction list

#### Scenario: User clicks Load more
- **WHEN** the user clicks "Load more"
- **THEN** the next page of transactions is fetched and appended to the list

#### Scenario: No more transactions
- **WHEN** all transactions have been loaded (no next cursor)
- **THEN** the "Load more" button is hidden

### Requirement: Token transfer list pagination
The token transfers tab SHALL support cursor-based pagination with a "Load more" button, using the token transfers API endpoint.

#### Scenario: More transfers available
- **WHEN** the address has more than 25 token transfers
- **THEN** a "Load more" button appears below the token transfer list

#### Scenario: User clicks Load more on transfers
- **WHEN** the user clicks "Load more" on the token transfers tab
- **THEN** the next page of token transfers is fetched and appended to the list

### Requirement: Balance formatting
The address page SHALL format the native token balance using BigInt division by 10^18, showing up to 6 decimal places, alongside the chain's native token symbol.

#### Scenario: Large balance
- **WHEN** an address has `balance_wei = "123456789012345678901"`
- **THEN** the displayed balance is "123.456789 ETH" (or the chain's native symbol)

#### Scenario: Zero balance
- **WHEN** an address has `balance_wei = "0"`
- **THEN** the displayed balance is "0 ETH"
