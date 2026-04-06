## ADDED Requirements

### Requirement: Effects section on transaction detail page
The transaction detail page SHALL include an "Effects" section that displays a human-readable timeline of what happened as a result of the transaction. Effects MUST be composed from token transfers and decoded event logs.

#### Scenario: Transaction with token transfers and decoded events
- **WHEN** a Uniswap swap transaction is viewed
- **THEN** the Effects section shows entries like:
  - "↓ 1.0 WETH from 0x7a25...488d to Pool"
  - "↑ 3,247 USDC from Pool to 0x7a25...488d"
  - "Swap on Uniswap V3 Pool"

#### Scenario: Transaction with only token transfers
- **WHEN** a simple ERC-20 transfer is viewed
- **THEN** the Effects section shows the token transfer

#### Scenario: No effects
- **WHEN** a transaction has no token transfers and no decoded logs
- **THEN** the Effects section shows "No decoded effects"

### Requirement: Effects deduplication
Token transfers derived from Transfer events and the decoded Transfer event log MUST NOT be shown as duplicate entries. The frontend MUST deduplicate by showing token transfers as the primary entries and only adding decoded logs that are NOT already represented as token transfers.

#### Scenario: Transfer event not duplicated
- **WHEN** a transaction has a token_transfer record AND a decoded Transfer log for the same event
- **THEN** only one entry appears in the Effects section (the token transfer)

### Requirement: Effects in BFF response
The BFF transaction detail endpoint already returns `logs` with the `decoded` field and `token_transfers`. No API changes are needed — the frontend composes the Effects view from existing response data.

#### Scenario: BFF returns decoded logs
- **WHEN** the BFF endpoint is called for a transaction with decoded logs
- **THEN** the response includes logs with non-null `decoded` JSONB containing `event_name`, `params`, and `summary`
