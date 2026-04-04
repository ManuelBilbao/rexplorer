# Real-time Subscription Workflow

## Overview

This workflow shows how clients receive real-time updates via Phoenix Channels. The indexer broadcasts events through PubSub after persisting blocks, and channel processes push them to connected WebSocket clients.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Client as WebSocket Client
    participant Socket as UserSocket
    participant Channel as BlockChannel
    participant PubSub as Phoenix.PubSub
    participant Indexer as Indexer Worker
    participant DB as PostgreSQL

    Note over Client,Channel: Connection + Subscription
    Client->>Socket: connect(/socket)
    Socket-->>Client: connected
    Client->>Channel: join("blocks:ethereum")
    Channel->>Channel: resolve slug → chain_id
    Channel->>PubSub: subscribe("chain:1:blocks")
    Channel-->>Client: joined

    Note over Indexer,DB: Block Indexed
    Indexer->>DB: persist block 20,000,001
    DB-->>Indexer: {:ok, _}
    Indexer->>PubSub: broadcast("chain:1:blocks", {:new_block, summary})

    Note over PubSub,Client: Push to Client
    PubSub->>Channel: {:new_block, summary}
    Channel->>Client: push("new_block", %{block_number: 20000001, ...})
```

## Address Activity

```mermaid
sequenceDiagram
    participant Client as WebSocket Client
    participant Channel as AddressChannel
    participant PubSub as Phoenix.PubSub
    participant Indexer as Indexer Worker

    Client->>Channel: join("address:ethereum:0xabc...")
    Channel->>PubSub: subscribe("chain:1:address:0xabc...")
    Channel-->>Client: joined

    Indexer->>PubSub: broadcast("chain:1:address:0xabc...", {:new_transaction, data})
    PubSub->>Channel: {:new_transaction, data}
    Channel->>Client: push("new_transaction", data)
```

## Available Topics

| Topic Pattern | Events | Description |
|---------------|--------|-------------|
| `blocks:<chain_slug>` | `new_block` | New block indexed on chain |
| `address:<chain_slug>:<hash>` | `new_transaction`, `new_token_transfer` | Activity on address |

## Connection Details

- **Endpoint:** `/socket`
- **Transport:** WebSocket
- **Authentication:** None (v1)
- **Library:** Any Phoenix Channel client (JavaScript, Elixir, etc.)
