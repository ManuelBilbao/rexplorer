## ADDED Requirements

### Requirement: Batches table
The system SHALL maintain a `batches` table with: `id` (bigint PK), `chain_id` (FK to chains), `batch_number` (integer), `first_block` (bigint), `last_block` (bigint), `status` (enum: `sealed`, `committed`, `verified`), `commit_tx_hash` (string, nullable), `verify_tx_hash` (string, nullable). A unique index on `(chain_id, batch_number)` SHALL prevent duplicates.

#### Scenario: Store a sealed batch
- **WHEN** a new batch is discovered via `ethrex_getBatchByBlock`
- **THEN** a record is created with status `sealed`, first_block and last_block populated, and commit/verify hashes null

#### Scenario: Batch transitions to committed
- **WHEN** a batch's commit_tx_hash becomes non-null via `ethrex_getBatchByNumber`
- **THEN** the batch status is updated to `committed` and `commit_tx_hash` is stored

#### Scenario: Batch transitions to verified
- **WHEN** a batch's verify_tx_hash becomes non-null
- **THEN** the batch status is updated to `verified` and `verify_tx_hash` is stored

### Requirement: Block-to-batch denormalization
For Ethrex chains, each block's `chain_extra` JSONB SHALL include a `batch_number` field, populated at index time via `ethrex_getBatchByBlock`. This enables O(1) block→batch lookup without range queries on the batches table.

#### Scenario: Block has batch_number in chain_extra
- **WHEN** a block is indexed on an Ethrex chain
- **THEN** its `chain_extra` contains `{"batch_number": 42}` (or null if not yet batched)

### Requirement: Batch Ecto schema
The system SHALL provide `Rexplorer.Schema.Batch` with associations to the chain and changeset validation.

#### Scenario: Insert and query a batch
- **WHEN** a batch record is inserted for chain 12345, batch_number 42
- **THEN** it can be queried by `(chain_id, batch_number)` via the unique index

### Requirement: Ethrex RPC extensions
The RPC client SHALL support Ethrex-specific methods:
- `ethrex_getBatchByBlock(block_identifier)` — returns batch info for a given block
- `ethrex_getBatchByNumber(batch_number, include_block_hashes)` — returns batch details
- `ethrex_batchNumber()` — returns latest batch number

#### Scenario: Fetch batch for a block
- **WHEN** `ethrex_getBatchByBlock("0x3E8")` is called
- **THEN** it returns batch info including batch_number, first_block, last_block, and optionally commit/verify tx hashes
