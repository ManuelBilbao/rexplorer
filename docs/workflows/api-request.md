# API Request Workflow

## Overview

This workflow shows how an API request flows through the Phoenix web layer, from router to JSON response.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Client
    participant Router as Phoenix Router
    participant Plug as ChainSlug Plug
    participant Ctrl as Controller
    participant Domain as Domain Query<br/>(Rexplorer.Blocks, etc.)
    participant Repo as Ecto Repo
    participant DB as PostgreSQL

    Client->>Router: GET /api/v1/chains/ethereum/blocks?before=20000000&limit=10
    Router->>Router: match :public_api pipeline

    Router->>Plug: ChainSlug.call(conn)
    Plug->>Domain: Chains.get_chain_by_slug("ethereum")
    Domain->>DB: SELECT FROM chains WHERE explorer_slug = 'ethereum'
    DB-->>Domain: chain record
    Domain-->>Plug: {:ok, chain}
    Plug->>Plug: assign(:chain_id, 1)

    Router->>Ctrl: BlockController.index(conn, params)
    Ctrl->>Ctrl: parse pagination params
    Ctrl->>Domain: Blocks.list_blocks(1, before: 20000000, limit: 10)
    Domain->>Repo: query with cursor + limit + 1
    Repo->>DB: SELECT FROM blocks WHERE chain_id=1 AND block_number < 20000000 ORDER BY block_number DESC LIMIT 11
    DB-->>Repo: 11 rows
    Repo-->>Domain: blocks
    Domain->>Domain: split into 10 results + next_cursor
    Domain-->>Ctrl: {:ok, blocks, next_cursor}

    Ctrl->>Ctrl: serialize to JSON
    Ctrl-->>Client: 200 {data: [...], next_cursor: 19999990}
```

## Two-Tier Architecture

```mermaid
graph LR
    subgraph "External Consumers"
        Dev[Developer]
        Wallet[Wallet App]
    end

    subgraph "Frontend"
        React[React SPA]
    end

    subgraph "rexplorer_web"
        PA["/api/v1/*<br/>Public API"]
        BFF["/internal/*<br/>BFF API"]
    end

    subgraph "rexplorer (core)"
        DQ[Domain Queries]
    end

    Dev --> PA
    Wallet --> PA
    React --> BFF
    PA --> DQ
    BFF --> DQ
```

The public API (`/api/v1/*`) and BFF (`/internal/*`) share the same domain query layer but have separate controllers and serialization. The public API is stable and versioned; the BFF is free to evolve with the UI.
