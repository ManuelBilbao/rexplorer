# Frontend Architecture

## Overview

The rexplorer frontend is a React SPA that consumes the two-tier API and Phoenix Channels for real-time updates.

## Data Flow

```mermaid
graph TD
    subgraph "Browser"
        Pages[React Pages]
        TQ[TanStack Query Cache]
        WS[Phoenix Socket]
    end

    subgraph "Phoenix (rexplorer_web)"
        BFF["/internal/* (BFF API)"]
        Public["/api/v1/* (Public API)"]
        Channels["Phoenix Channels"]
    end

    subgraph "Core (rexplorer)"
        DQ[Domain Queries]
        PubSub[Phoenix PubSub]
    end

    DB[(PostgreSQL)]

    Pages -->|"useHomeData(), useTxDetail()"| TQ
    TQ -->|"fetch"| BFF
    TQ -->|"fetch"| Public
    Pages -->|"useBlockSubscription()"| WS
    WS -->|"WebSocket"| Channels

    BFF --> DQ
    Public --> DQ
    Channels -->|"subscribe"| PubSub
    DQ --> DB
```

## Real-time Flow

```mermaid
sequenceDiagram
    participant Indexer as Indexer Worker
    participant PubSub as Phoenix PubSub
    participant Channel as Phoenix Channel
    participant Socket as phoenix.js Socket
    participant Hook as useBlockSubscription
    participant Page as HomePage

    Indexer->>PubSub: broadcast new_block
    PubSub->>Channel: {:new_block, data}
    Channel->>Socket: push("new_block", payload)
    Socket->>Hook: callback(payload)
    Hook->>Page: setLatestBlock(payload)
    Page->>Page: prepend to block list
```

## Key Decisions

- **Custom component library** — no third-party UI framework. All components in `src/components/ui/` built with Tailwind CSS.
- **Two data sources** — pages use BFF (`/internal/*`) for aggregated data; public API (`/api/v1/*`) for simple lists.
- **TanStack Query** — handles caching, deduplication, loading/error states. Navigating back to a cached page is instant.
- **Dark mode** — Tailwind `class` strategy, persisted in localStorage, defaults to system preference.
