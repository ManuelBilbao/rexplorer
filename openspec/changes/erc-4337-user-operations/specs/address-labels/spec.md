## Purpose

Gives addresses a human-readable role name derived from how they were used on-chain, so that an EntryPoint, a paymaster or a smart account reads as what it is everywhere an address is rendered.

## ADDED Requirements

### Requirement: Role labels written at index time
The system SHALL derive role labels for addresses while indexing and store them on the address record for the chain on which they were observed. The initial roles are the ERC-4337 ones:
- the EntryPoint a bundle was submitted to — labelled with its version, e.g. `ERC-4337 EntryPoint v0.7`
- an address that sponsored a UserOperation — `ERC-4337 Paymaster`
- an address that was the `sender` of a UserOperation — `Smart Account`
- an address that deployed a smart account through `initCode` — `ERC-4337 Account Factory`

A label MUST describe an observed on-chain role, never a guess about ownership or identity.

#### Scenario: EntryPoint labelled from a bundle
- **WHEN** a `handleOps` transaction is indexed
- **THEN** the address it was sent to is labelled as an EntryPoint with the version implied by the calldata shape

#### Scenario: Smart account labelled
- **WHEN** an address appears as the sender of a UserOperation
- **THEN** that address is labelled `Smart Account` on that chain

#### Scenario: Paymaster labelled
- **WHEN** a UserOperation is sponsored
- **THEN** the paymaster address is labelled `ERC-4337 Paymaster` on that chain

#### Scenario: Label visible to a regular user
- **WHEN** a user opens an address page or sees the address in a transaction
- **THEN** the role label is shown alongside the address, so the page reads "Smart Account 0xabc…" rather than a bare hex string

### Requirement: Labels are per chain and never silently overwritten
Labels SHALL be scoped to `(chain_id, address)`, matching how address records are already keyed. Writing a label MUST NOT overwrite a label that is already present: the first observed role wins, so re-indexing or a later block cannot flip an address's label back and forth.

#### Scenario: Same address, two chains
- **WHEN** the same 20-byte address is an EntryPoint on one chain and unused on another
- **THEN** only the record for the chain where it was observed carries the label

#### Scenario: Existing label preserved
- **WHEN** an address already carries a label and is observed again in a new role
- **THEN** the existing label is kept unchanged

#### Scenario: Unlabelled address
- **WHEN** an address has never been observed in a known role
- **THEN** its label is absent and every surface renders the plain address as before

### Requirement: Labels exposed through the APIs
Address labels SHALL be returned by the address endpoints that already expose a `label` field, so that clients need no new call to render them.

#### Scenario: Address detail includes label
- **WHEN** an address with a role label is requested from the public or BFF address endpoint
- **THEN** the response's `label` field carries the role name

#### Scenario: Search result includes label
- **WHEN** a search resolves to a labelled address
- **THEN** the result carries the label so the UI can show the role in the result row
