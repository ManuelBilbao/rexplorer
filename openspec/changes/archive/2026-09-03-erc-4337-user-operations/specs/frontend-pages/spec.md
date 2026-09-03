## MODIFIED Requirements

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
