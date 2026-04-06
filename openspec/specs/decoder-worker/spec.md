## ADDED Requirements

### Requirement: Async decoder worker
The system SHALL provide `Rexplorer.Decoder.Worker` as a GenServer that periodically queries for operations needing decoding and processes them in batches. It MUST run independently from the indexer.

#### Scenario: Process new operations
- **WHEN** new operations with `decoder_version IS NULL` exist in the database
- **THEN** the worker picks them up, runs the decoder pipeline, and updates `decoded_summary` and `decoder_version`

#### Scenario: Reprocess on version bump
- **WHEN** the decoder version is incremented (new interpreters added)
- **THEN** the worker reprocesses operations where `decoder_version < current_version`

### Requirement: Batch processing
The worker MUST process operations in configurable batches (default: 100). After processing a batch, if more operations remain, it MUST immediately process the next batch. If no operations remain, it MUST wait a configurable interval (default: 5 seconds) before polling again.

#### Scenario: Large backlog
- **WHEN** 10,000 undecoded operations exist
- **THEN** the worker processes them in batches of 100 without pausing between batches

#### Scenario: Caught up
- **WHEN** no undecoded operations remain
- **THEN** the worker waits 5 seconds before polling again

### Requirement: Decoder version constant
The system SHALL define a `@decoder_version` constant in the pipeline module. This version MUST be incremented whenever new interpreters are added or existing ones change behavior. The worker uses this to determine which operations need (re)processing.

#### Scenario: Version check
- **WHEN** the worker queries for operations to process
- **THEN** it selects `WHERE decoder_version IS NULL OR decoder_version < @decoder_version`

### Requirement: Graceful failure handling
If decoding fails for a single operation (e.g., malformed calldata), the worker MUST log the error and skip that operation. It MUST NOT halt or stop processing the batch. Failed operations MUST have `decoder_version` set to the current version with `decoded_summary` set to `nil` to avoid reprocessing them indefinitely.

#### Scenario: Malformed calldata
- **WHEN** an operation has calldata that cannot be decoded
- **THEN** the worker sets `decoder_version` to current and `decoded_summary` to `nil`, and continues to the next operation

### Requirement: Supervision
The decoder worker MUST be started as part of the `rexplorer` core application supervision tree (not the indexer). It MUST restart on crash with backoff.

#### Scenario: Worker crashes and restarts
- **WHEN** the decoder worker crashes
- **THEN** the supervisor restarts it and it resumes from the next undecoded batch
