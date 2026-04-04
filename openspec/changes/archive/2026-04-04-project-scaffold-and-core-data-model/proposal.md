## Why

Rexplorer needs a runnable foundation before any feature work can begin. This means a Phoenix umbrella project structure, a PostgreSQL database with a core data model, and the initial chain adapter scaffolding. The data model is particularly critical because it introduces the **operation** abstraction — the fundamental unit that separates rexplorer from traditional explorers that treat transactions as atomic. Getting this right now avoids costly migrations later.

## What Changes

- **Phoenix umbrella project** with three apps: `rexplorer` (shared core/domain), `rexplorer_indexer` (chain ingestion), `rexplorer_web` (presentation layer)
- **Core Ecto schemas and migrations** for: chains, blocks, transactions, operations, token transfers, addresses, logs/events, cross-chain links
- **Chain adapter behaviour** (`Rexplorer.Chain.Adapter`) defining the contract that each chain implementation must fulfill
- **Ethereum mainnet adapter stub** as the reference implementation
- **Project documentation foundation**: architecture overview, data model docs with ER diagrams, and workflow documentation templates with Mermaid sequence diagrams

## Non-goals

- Actual chain indexing logic (that's a subsequent change)
- The semantic decoder pipeline (ABI decode → Unwrap → Interpret → Narrate)
- Frontend/UI (LiveView vs React decision deferred)
- API endpoints
- Deployment or infrastructure setup

## Capabilities

### New Capabilities
- `core-data-model`: Ecto schemas for blocks, transactions, operations, addresses, token transfers, logs, cross-chain links — the foundational data layer
- `chain-adapter`: Elixir behaviour defining the multi-chain adapter contract, with Ethereum mainnet as reference stub
- `project-structure`: Phoenix umbrella app layout, configuration, and documentation scaffolding

### Modified Capabilities
*(none — greenfield project)*

## Impact

- Creates the entire project directory structure (Phoenix umbrella)
- Establishes PostgreSQL as the database
- Defines the core schema that all future features build upon
- Sets the documentation standard (Mermaid diagrams for all workflows)

### Architectural fit
This is layer 0 of rexplorer. The operation abstraction, multi-chain chain_id pattern, and JSONB extension columns established here directly enable the decoder pipeline, AA support, and L2 lifecycle features that follow.
