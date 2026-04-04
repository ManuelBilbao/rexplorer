## Why

Rexplorer has an indexer populating the database with blocks, transactions, operations, and token transfers — but no way to query that data. This change adds both a public REST API (a first-class product for external developers, wallets, and analytics tools) and a Backend-for-Frontend (BFF) API optimized for the upcoming React UI. It also adds Phoenix Channels for real-time WebSocket subscriptions.

## What Changes

- **Public REST API (`/api/v1/*`)** — Stable, versioned endpoints for querying blocks, transactions, operations, addresses, token transfers, logs, and chains. Designed for external consumers. Follows RESTful conventions with consistent pagination, filtering, and error responses.
- **Backend-for-Frontend API (`/internal/*`)** — UI-optimized endpoints that aggregate multiple resources in a single call (e.g., transaction detail page with operations + transfers + cross-chain links). Not publicly documented, free to evolve with the UI.
- **Phoenix Channels** — Real-time WebSocket subscriptions for new blocks, address activity, and chain status. Used by both the future React UI and external consumers who want push notifications.
- **API documentation** — OpenAPI/Swagger spec for the public API, auto-generated from controller annotations.
- **Shared domain layer** — Query modules in the core `rexplorer` app (`Rexplorer.Blocks`, `Rexplorer.Transactions`, etc.) that both API tiers consume. These encapsulate Ecto queries and preloading logic.

## Non-goals

- **React frontend** — The UI is a separate change that will consume these APIs
- **Authentication / API keys** — Public API is open for v1 (rate limiting deferred)
- **Rate limiting** — Deferred to a follow-up change
- **GraphQL** — REST only for v1; GraphQL can be layered on later
- **Write operations** — No transaction submission, no contract interaction. Read-only API.

## Capabilities

### New Capabilities
- `public-api`: Versioned REST API at `/api/v1/*` for blocks, transactions, operations, addresses, token transfers, logs, and chains
- `bff-api`: UI-optimized endpoints at `/internal/*` aggregating resources for frontend pages (transaction detail, address overview, home page)
- `realtime-channels`: Phoenix Channel subscriptions for new blocks, address activity, and chain status updates
- `domain-queries`: Shared query modules in the core app (`Rexplorer.Blocks`, `Rexplorer.Transactions`, etc.) used by both API tiers

### Modified Capabilities
*(none)*

## Impact

- **`apps/rexplorer/`** — New domain query modules (`Rexplorer.Blocks`, `Rexplorer.Transactions`, `Rexplorer.Addresses`, `Rexplorer.Chains`)
- **`apps/rexplorer_web/`** — New controllers, JSON views, router config, error handling, pagination, channels
- **`config/`** — CORS configuration for cross-origin React app access
- **Dependencies** — `open_api_spex` for OpenAPI spec generation, `cors_plug` for CORS

### Architectural fit
This change establishes the two-tier API pattern that separates the public developer API from the UI's data needs. The domain query layer in the core app ensures both tiers (and future tiers like GraphQL) share the same business logic. The Phoenix Channels provide the real-time foundation that the React UI will consume for live block feeds and L2 lifecycle tracking.
