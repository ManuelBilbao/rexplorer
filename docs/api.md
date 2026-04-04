# Rexplorer Public API

## Base URL

```
/api/v1
```

All endpoints are prefixed with `/api/v1`. Chains are identified by their `explorer_slug` (e.g., `ethereum`, `optimism`, `base`).

## Authentication

No authentication required for v1. All blockchain data is public.

## Pagination

List endpoints use semantic cursor-based pagination:

| Resource | Cursor Parameter | Example |
|----------|-----------------|---------|
| Blocks | `before` (block_number) | `?before=20000000&limit=10` |
| Transactions | `before_block` + `before_index` | `?before_block=20000000&before_index=5&limit=25` |
| Token transfers | `before` (id) | `?before=123456&limit=25` |

Default limit: 25. Maximum: 100.

Responses include `next_cursor` (null if no more results).

## Error Responses

All errors follow a consistent format:

```json
{"error": "<code>", "message": "<description>"}
```

| Status | Code | When |
|--------|------|------|
| 400 | `bad_request` | Invalid parameters |
| 404 | `not_found` | Resource doesn't exist |
| 422 | `validation_error` | Validation failed |
| 500 | `internal_error` | Server error |

---

## Endpoints

### Chains

#### `GET /api/v1/chains`

List all enabled chains.

**Response:**
```json
{
  "data": [
    {
      "chain_id": 1,
      "name": "Ethereum",
      "chain_type": "l1",
      "native_token_symbol": "ETH",
      "explorer_slug": "ethereum"
    }
  ]
}
```

#### `GET /api/v1/chains/:slug`

Get a chain by slug.

---

### Blocks

#### `GET /api/v1/chains/:chain_slug/blocks`

List recent blocks (paginated).

**Query params:** `before` (block_number), `limit` (1-100)

**Response:**
```json
{
  "data": [
    {
      "block_number": 20000000,
      "hash": "0x...",
      "parent_hash": "0x...",
      "timestamp": "2024-01-01T00:00:00Z",
      "gas_used": 15000000,
      "gas_limit": 30000000,
      "base_fee_per_gas": 1000000000,
      "transaction_count": 150
    }
  ],
  "next_cursor": 19999990
}
```

#### `GET /api/v1/chains/:chain_slug/blocks/:number`

Get a block by number.

---

### Transactions

#### `GET /api/v1/chains/:chain_slug/transactions`

List transactions (paginated, filterable by address).

**Query params:** `address`, `before_block`, `before_index`, `limit`

#### `GET /api/v1/chains/:chain_slug/transactions/:hash`

Get a transaction by hash.

**Response:**
```json
{
  "data": {
    "hash": "0x...",
    "from_address": "0x...",
    "to_address": "0x...",
    "value": "1000000000000000000",
    "gas_price": 1000000000,
    "gas_used": 21000,
    "nonce": 42,
    "status": true,
    "transaction_type": 2,
    "transaction_index": 0,
    "block_number": 20000000
  }
}
```

---

### Operations

#### `GET /api/v1/chains/:chain_slug/transactions/:hash/operations`

List operations (user intents) for a transaction.

**Response:**
```json
{
  "data": [
    {
      "operation_type": "call",
      "operation_index": 0,
      "from_address": "0x...",
      "to_address": "0x...",
      "value": "1000000000000000000",
      "decoded_summary": "Swapped 1 ETH for 3,247 USDC on Uniswap V3"
    }
  ]
}
```

---

### Addresses

#### `GET /api/v1/chains/:chain_slug/addresses/:hash`

Get address metadata.

#### `GET /api/v1/chains/:chain_slug/addresses/:hash/token-transfers`

List token transfers for an address (paginated).

**Query params:** `before` (id), `limit`

---

## WebSocket Channels

Connect to `/socket` for real-time updates.

### `blocks:<chain_slug>`

Receive `new_block` events when blocks are indexed.

### `address:<chain_slug>:<address_hash>`

Receive `new_transaction` and `new_token_transfer` events.
