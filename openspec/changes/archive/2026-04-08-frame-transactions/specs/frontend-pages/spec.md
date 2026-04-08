## MODIFIED Requirements

### Requirement: Transaction detail page
The transaction detail page (`/:chain/tx/:hash`) SHALL detect frame transactions (type `0x06`) and display frames as expandable sections. Each frame section MUST show: frame index, mode label (VERIFY/SENDER/DEFAULT), target address, gas used, and status. SENDER frames SHALL show their decoded operation summary and token transfers. VERIFY frames SHALL show "Signature verification." The page MUST also display the `payer` address when it differs from the sender.

#### Scenario: Frame transaction detail page
- **WHEN** the user views a frame transaction
- **THEN** the page shows a "Frames" section with each frame as an expandable row showing mode, target, gas, status, and decoded operations

#### Scenario: Sponsored frame transaction
- **WHEN** the user views a frame transaction where `payer != sender`
- **THEN** the page shows both "Sender" and "Payer" in the transaction header

#### Scenario: Regular transaction unchanged
- **WHEN** the user views a non-frame transaction
- **THEN** the page displays as before with no frames section

### Requirement: Address overview page
The address page SHALL include transactions where the address appears as a frame target, not just as `from_address` or `to_address`.

#### Scenario: Frame-targeted transactions visible
- **WHEN** a user views an address page for an address that is only targeted by frame txs
- **THEN** those frame transactions appear in the Transactions tab
