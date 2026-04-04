## ADDED Requirements

### Requirement: Phoenix umbrella application structure
The system SHALL be organized as a Phoenix umbrella application with three child apps:

- `rexplorer` — shared domain logic, Ecto schemas, chain adapters, business logic
- `rexplorer_indexer` — chain data ingestion (no web dependencies)
- `rexplorer_web` — Phoenix web layer (controllers, views, templates, channels)

Each app MUST have its own `mix.exs` with explicit dependencies on sibling apps where needed.

#### Scenario: Apps compile independently
- **WHEN** `mix compile` is run in the `rexplorer` app directory
- **THEN** it compiles successfully without requiring `rexplorer_web` or `rexplorer_indexer`

#### Scenario: Web app depends on core
- **WHEN** `rexplorer_web` starts
- **THEN** it has access to all schemas and functions from the `rexplorer` core app

#### Scenario: Indexer app depends on core
- **WHEN** `rexplorer_indexer` starts
- **THEN** it has access to all schemas and chain adapters from the `rexplorer` core app, but does NOT depend on `rexplorer_web`

### Requirement: Database configuration
The system SHALL use PostgreSQL as its primary database. The Ecto Repo SHALL be defined in the `rexplorer` core app and shared across all child apps. Database configuration MUST support per-environment settings (dev, test, prod) with sensible defaults.

#### Scenario: Development database setup
- **WHEN** a developer runs `mix ecto.create && mix ecto.migrate` in the umbrella root
- **THEN** the PostgreSQL database `rexplorer_dev` is created and all migrations run successfully

#### Scenario: Test database isolation
- **WHEN** tests run via `mix test`
- **THEN** they use a separate `rexplorer_test` database with the Ecto sandbox for isolation

### Requirement: Architecture documentation
The system SHALL include an `docs/architecture.md` file that documents:

- The umbrella app structure and responsibilities of each app
- The core data model with a Mermaid ER diagram
- The chain adapter extension pattern
- How data flows through the system

#### Scenario: Architecture doc includes ER diagram
- **WHEN** a developer opens `docs/architecture.md`
- **THEN** it contains a Mermaid ER diagram showing all core tables and their relationships

### Requirement: Workflow documentation
The system SHALL include documentation for each system workflow with Mermaid sequence diagrams. Initial workflows to document:

- **Block indexing workflow**: how a block goes from RPC node to database
- **Transaction lookup workflow**: how a user query resolves to transaction data
- **Address view workflow**: how address page data is assembled

Each workflow document SHALL live in `docs/workflows/` as a separate markdown file.

#### Scenario: Indexing workflow documented
- **WHEN** a developer opens `docs/workflows/block-indexing.md`
- **THEN** it contains a Mermaid sequence diagram showing the flow: RPC Node → Indexer → Chain Adapter → Ecto → PostgreSQL

#### Scenario: Transaction lookup workflow documented
- **WHEN** a developer opens `docs/workflows/transaction-lookup.md`
- **THEN** it contains a Mermaid sequence diagram showing how a tx hash query flows through the web layer to the database and back, including operation loading

### Requirement: Code documentation standards
All public modules and functions SHALL include `@moduledoc` and `@doc` attributes. Ecto schemas SHALL document each field's purpose. Chain adapter behaviour callbacks SHALL have `@doc` attributes explaining the expected return values and semantics.

#### Scenario: Schema module has documentation
- **WHEN** a developer reads the `Rexplorer.Schema.Transaction` module
- **THEN** it has a `@moduledoc` explaining the transaction schema and a `@doc` or inline comment for each non-obvious field

#### Scenario: Behaviour callbacks are documented
- **WHEN** a developer reads the `Rexplorer.Chain.Adapter` behaviour
- **THEN** each callback has a `@doc` explaining its purpose, expected input, and return type
