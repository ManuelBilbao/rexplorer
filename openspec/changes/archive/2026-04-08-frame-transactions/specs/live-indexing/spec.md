## ADDED Requirements

### Requirement: Frame persistence during block indexing
The indexer worker SHALL persist frame records from the BlockProcessor result within the same atomic database transaction as blocks, transactions, logs, and other data.

#### Scenario: Frames persisted atomically
- **WHEN** a block containing a frame transaction is indexed
- **THEN** the frame records are inserted in the same DB transaction as the parent transaction, logs, and operations
