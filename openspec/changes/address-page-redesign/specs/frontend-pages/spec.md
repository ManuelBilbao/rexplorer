## MODIFIED Requirements

### Requirement: Address page
The address page (`/:chain/address/:hash`) SHALL display a comprehensive address overview including: stat cards (Balance, Last Active, First Seen), a balance history area chart, and tabbed sections for transactions and token transfers with cursor-based pagination. The page MUST fetch data from the BFF address overview endpoint for initial load and the balance history endpoint for chart data.

#### Scenario: Full address page load
- **WHEN** the user navigates to `/:chain/address/:hash`
- **THEN** the page displays the address header, stat cards, balance chart, and tabbed transaction/transfer sections

#### Scenario: Loading state
- **WHEN** the address data is being fetched
- **THEN** skeleton placeholders are shown for stat cards, chart, and list sections
