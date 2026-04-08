## ADDED Requirements

### Requirement: Internal transaction persistence during block indexing
On chains with trace support, the indexer worker SHALL persist internal transactions from the trace data within the same atomic database transaction as blocks, transactions, and balance changes.

#### Scenario: Block with internal transactions
- **WHEN** block N is indexed on a chain with trace support and the trace contains 5 value-transferring internal calls
- **THEN** 5 `internal_transactions` rows are inserted in the same DB transaction

#### Scenario: Chain without trace support
- **WHEN** block N is indexed on a chain without trace support
- **THEN** no internal transactions are persisted and no trace RPC call is made
