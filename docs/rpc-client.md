# RPC Client

## Overview

`Rexplorer.RPC.Client` is a stateless JSON-RPC client for communicating with Ethereum-compatible blockchain nodes. It lives in the core `rexplorer` app and can be used by both the indexer and the web layer.

## API

### `call(url, method, params \\ [])`

Makes a single JSON-RPC call.

```elixir
{:ok, result} = Rexplorer.RPC.Client.call("http://localhost:8545", "eth_blockNumber", [])
# result = "0x1312D00"
```

**Returns:**
- `{:ok, result}` — successful call, `result` is the decoded JSON-RPC result
- `{:error, %{code: integer, message: string}}` — JSON-RPC error
- `{:error, reason}` — network or HTTP error

### `get_latest_block_number(url)`

Returns the chain's current head block number as an integer.

```elixir
{:ok, 20_000_000} = Rexplorer.RPC.Client.get_latest_block_number(url)
```

### `get_block(url, block_number)`

Fetches a block by number with full transaction objects.

```elixir
{:ok, block_map} = Rexplorer.RPC.Client.get_block(url, 20_000_000)
# block_map["transactions"] contains full tx objects
```

Returns `{:ok, nil}` if the block doesn't exist yet.

### `get_block_receipts(url, block_number)`

Fetches all transaction receipts for a block in a single call.

```elixir
{:ok, receipts} = Rexplorer.RPC.Client.get_block_receipts(url, 20_000_000)
# receipts is a list of receipt maps
```

## Hex Helpers

The client also exposes hex encoding/decoding utilities:

| Function | Input | Output |
|----------|-------|--------|
| `hex_to_integer("0xFF")` | Hex string | `255` |
| `integer_to_hex(255)` | Integer | `"0xFF"` |
| `hex_to_binary("0xDEAD")` | Hex string | `<<0xDE, 0xAD>>` |

## Configuration

The RPC client is stateless — it takes a URL as its first argument. RPC URLs are configured per-chain in the indexer config:

```elixir
# config/config.exs
config :rexplorer_indexer,
  chains: %{
    1 => %{rpc_url: "http://localhost:8545"},
    10 => %{rpc_url: "http://localhost:9545"}
  }
```

## Error Handling

- Network errors (timeouts, connection refused) return `{:error, exception}`
- JSON-RPC errors return `{:error, %{code: code, message: message}}`
- The client never raises — all errors are returned as tuples
- Callers (e.g., the indexer worker) are responsible for retry logic

## Dependencies

Uses [Req](https://hexdocs.pm/req) (built on Finch) for HTTP with built-in connection pooling and JSON encoding.
