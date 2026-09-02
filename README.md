# Rexplorer

A multi-chain Ethereum-like blockchain explorer built with Elixir/Phoenix and React. Designed from the ground up for the multi-chain L2 reality.

## What makes it different

- **Human-readable transaction stories** — shows what happened, not just what was called. Decodes multisig executions, AA user operations, and multicalls into plain language.
- **Cross-chain journey tracking** — follows transactions across L1/L2 bridges as one unified story.
- **Account Abstraction native** — understands UserOperations, paymasters, and smart wallets from day one.
- **L2 lifecycle visibility** — tracks transaction finality: sequenced, batched, proved, finalized.
- **Chain-extensible** — adapter system lets each chain plug in its own logic at every layer.

## Quickstart

### Prerequisites

[Nix](https://nixos.org/download/) with flakes enabled — that is the only host
requirement. Every `make` target runs inside `nix develop`, which provides
Elixir 1.19 / Erlang OTP 28, PostgreSQL 18, Node.js 22 and pnpm, and starts a
project-local Postgres on a Unix socket in `.pg-socket` (no system service, no
port 5432 conflict).

If you use [direnv](https://direnv.net/), `direnv allow` loads the same
environment automatically on `cd`.

### Setup

```bash
git clone <repo-url> rexplorer && cd rexplorer

# Elixir deps + database + frontend deps, all inside Nix
make setup
```

`make shell` drops you into an interactive dev shell if you would rather run
`mix` and `pnpm` by hand.

### Run

```bash
# Terminal 1: Phoenix backend (API + indexer)
make server

# Terminal 2: React frontend (Vite dev server)
make frontend.dev
```

- Frontend: http://localhost:5173
- API: http://localhost:4000/api/v1/chains
- Swagger UI: http://localhost:4000/swaggerui
- OpenAPI spec: http://localhost:4000/api/openapi

### Test

```bash
make test                  # Elixir tests
make frontend.typecheck    # TypeScript type checking
make frontend.build        # Verify frontend builds
```

## Architecture

```
rexplorer/
├── backend/                     Elixir umbrella — API, indexer, domain logic
│   ├── apps/
│   │   ├── rexplorer/           Core domain — schemas, chain adapters, RPC client, query modules
│   │   ├── rexplorer_indexer/   Chain data ingestion — per-chain workers, block processor
│   │   └── rexplorer_web/       Phoenix web — public API, BFF API, channels, Swagger
│   └── config/                  Shared configuration
├── frontend/                    React SPA — custom component library, pages, real-time hooks
├── nix/                         Nix packages and the NixOS deployment module
├── docs/                        Architecture docs, workflow diagrams, API reference
└── openspec/                    Change management and decision records
```

### Umbrella Apps

| App | Responsibility | Can be deployed independently |
|-----|---------------|------------------------------|
| `rexplorer` | Ecto schemas, chain adapters, domain queries, RPC client | Shared library |
| `rexplorer_indexer` | Fetches blocks from RPC nodes, processes and persists them | Yes (indexer nodes) |
| `rexplorer_web` | REST API, BFF API, Phoenix Channels, Swagger | Yes (web nodes) |

### Two-tier API

| Tier | Path | Purpose | Stability |
|------|------|---------|-----------|
| Public API | `/api/v1/*` | External developers, wallets, analytics | Versioned, stable |
| BFF API | `/internal/*` | React frontend, aggregated views | Free to evolve |

### Supported Chains

| Chain | ID | Type |
|-------|----|------|
| Ethereum | 1 | L1 |
| Optimism | 10 | Optimistic Rollup |
| Base | 8453 | Optimistic Rollup |
| BNB Smart Chain | 56 | Sidechain |
| Polygon | 137 | Sidechain |

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/architecture.md`](docs/architecture.md) | System overview, data model ER diagram, app responsibilities |
| [`docs/api.md`](docs/api.md) | Public API reference with examples |
| [`docs/chain-adapters.md`](docs/chain-adapters.md) | How to implement a new chain adapter |
| [`docs/rpc-client.md`](docs/rpc-client.md) | RPC client API and configuration |
| [`docs/frontend.md`](docs/frontend.md) | Frontend architecture and data flow |
| [`frontend/README.md`](frontend/README.md) | Frontend setup, stack, component library |
| [`docs/deployment.md`](docs/deployment.md) | Nix dev shell, release artifacts, NixOS deployment |

### Workflow Diagrams (Mermaid)

| Workflow | Description |
|----------|-------------|
| [`docs/workflows/block-indexing.md`](docs/workflows/block-indexing.md) | How blocks flow from RPC node to database |
| [`docs/workflows/indexer-startup.md`](docs/workflows/indexer-startup.md) | Application boot, chain discovery, worker startup |
| [`docs/workflows/transaction-lookup.md`](docs/workflows/transaction-lookup.md) | How a tx hash query resolves to a full response |
| [`docs/workflows/address-view.md`](docs/workflows/address-view.md) | How the address page assembles its data |
| [`docs/workflows/api-request.md`](docs/workflows/api-request.md) | Request flow through the API layer |
| [`docs/workflows/realtime-subscription.md`](docs/workflows/realtime-subscription.md) | WebSocket channel subscription flow |
| [`docs/deployment.md`](docs/deployment.md) | Dev shell startup, request routing, scale-out topology |

### Decision Records

Architectural decisions are preserved in `openspec/changes/archive/`. Each change includes a proposal (why), design (how), specs (what), and tasks (implementation checklist).

## Deployment (Nix / NixOS)

The flake produces three artifacts:

| Output | What it is |
|--------|-----------|
| `.#rexplorer-web` | Mix release of the Phoenix web tier (`bin/rexplorer_web`) |
| `.#rexplorer-indexer` | Mix release of the indexer tier (`bin/rexplorer_indexer`) |
| `.#rexplorer-frontend` | Static React bundle |

```bash
make nix.build           # Build all three
```

The web and indexer ship as separate releases so they can be scaled
independently, matching the umbrella's app boundaries.

`nixosModules.rexplorer` wires them into systemd units, PostgreSQL, and an
Nginx vhost that serves the SPA and proxies `/api`, `/internal`, `/swaggerui`
and the `/socket` WebSocket to Phoenix. See
[`nix/server-example.nix`](nix/server-example.nix) for a complete host config.

```nix
services.rexplorer = {
  enable = true;
  domain = "explorer.example.com";
  frontendPath = "/opt/rexplorer/frontend";
  envFile = "/etc/rexplorer/env";   # DATABASE_URL + SECRET_KEY_BASE
  nginx.acmeEmail = "admin@example.com";
};
```

Set `enableIndexer = false` on web-only nodes so one database is not indexed
by several machines at once.

## Makefile Reference

Every target runs inside `nix develop`.

```bash
make help                # Show all available commands
make shell               # Interactive Nix dev shell
make setup               # Full project setup (deps + DB + frontend)
make server              # Start Phoenix server
make test                # Run Elixir tests
make frontend.dev        # Start frontend dev server
make frontend.build      # Build frontend for production
make frontend.typecheck  # TypeScript type checking
make db.reset            # Drop, create, migrate, and seed database
make services.start      # Start the project-local Postgres
make nix.build           # Build release artifacts
```

## License

[MIT](LICENSE)
