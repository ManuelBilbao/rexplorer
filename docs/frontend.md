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

## Component Architecture

```mermaid
graph TD
    subgraph "Pages"
        HP[HomePage]
        BLP[BlockListPage]
        BDP[BlockDetailPage]
        TDP[TxDetailPage]
        AP[AddressPage]
    end

    subgraph "Explorer Components"
        SB[StatusBadge]
        CB[ChainBadge]
        AD[AddressDisplay]
        BN[BlockNumber]
        TH[TxHash]
        TA[TimeAgo]
        TA2[TokenAmount]
        ES[EffectsSection]
        BC[BalanceChart]
    end

    subgraph "UI Components"
        Badge
        Button
        DataTable
        Skeleton
        Tabs
        Modal
        Dropdown
        Tooltip
        Toast
    end

    HP --> BN & TA & Skeleton
    BLP --> DataTable & BN & TA
    BDP --> DataTable & Skeleton & AD & TH
    TDP --> SB & CB & BN & AD & TA & Badge & Button & Skeleton
    AP --> SB & AD & TH & TA & Badge & Button & Skeleton & Tabs & BC

    SB --> Badge
    CB --> Badge
    DataTable --> Skeleton & Button
```

### Component usage guidelines

| When rendering... | Use this component |
|---|---|
| Transaction status (success/fail/pending) | `StatusBadge` |
| Chain name with color dot | `ChainBadge` |
| Blockchain address (with link + copy) | `AddressDisplay` |
| Block number (with link) | `BlockNumber` |
| Transaction hash (with link + copy) | `TxHash` |
| Relative timestamps | `TimeAgo` (not `timeAgo()` utility) |
| Token amounts with decimals | `TokenAmount` |
| Tabular data with pagination | `DataTable` (with `onLoadMore`/`hasMore`) |
| Loading placeholders | `Skeleton` (not raw `animate-pulse` divs) |
| Label/tag badges | `Badge` |
| Clickable actions | `Button` |

Explorer components (`StatusBadge`, `ChainBadge`) delegate to UI components (`Badge`) internally. Pages should never re-implement badge or status rendering inline.

## Key Decisions

- **Custom component library** — no third-party UI framework. All components in `src/components/ui/` built with Tailwind CSS.
- **Two data sources** — pages use BFF (`/internal/*`) for aggregated data; public API (`/api/v1/*`) for simple lists.
- **TanStack Query** — handles caching, deduplication, loading/error states. Navigating back to a cached page is instant.
- **Dark mode** — Tailwind `class` strategy, persisted in localStorage, defaults to system preference.
