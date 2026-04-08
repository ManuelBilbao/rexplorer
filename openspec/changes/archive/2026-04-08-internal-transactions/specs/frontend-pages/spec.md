## MODIFIED Requirements

### Requirement: Address page
The address page (`/:chain/address/:hash`) SHALL display a comprehensive address overview including: stat cards, balance history chart, and tabbed sections for Transactions, Internal Transactions, and Token Transfers. The Internal Transactions tab SHALL only be shown for chains that support traces.

#### Scenario: Address page on chain with trace support
- **WHEN** the user navigates to an address page on an Ethrex L2 chain
- **THEN** the page shows three tabs: Transactions, Internal Txns, Token Transfers

#### Scenario: Address page on chain without trace support
- **WHEN** the user navigates to an address page on a chain without trace support
- **THEN** the page shows two tabs: Transactions, Token Transfers (no Internal Txns tab)

#### Scenario: Internal transactions tab shows deposits
- **WHEN** the user views the Internal Txns tab for an address that received deposits
- **THEN** the deposit internal transactions are listed showing from, to, value, and call type
