## 1. Dependencies and Router Setup

- [x] 1.1 Add `cors_plug` and `open_api_spex` dependencies to `apps/rexplorer_web/mix.exs` and run `mix deps.get`
- [x] 1.2 Configure router with two pipelines: `:public_api` (JSON + CORS + versioning) and `:internal_api` (JSON + CORS). Add scope `/api/v1` and `/internal`
- [x] 1.3 Create `RexplorerWeb.Plugs.ChainSlug` plug that resolves `:chain_slug` param to `chain_id` using `Rexplorer.Chains.get_chain_by_slug/1` and assigns it to `conn.assigns`
- [x] 1.4 Create `RexplorerWeb.FallbackController` for consistent error rendering (404, 400, 422, 500)
- [x] 1.5 Configure CORS in endpoint for cross-origin React app access

## 2. Domain Query Modules (Core App)

- [x] 2.1 Implement `Rexplorer.Chains` with `list_enabled_chains/0` and `get_chain_by_slug/1`
- [x] 2.2 Implement `Rexplorer.Blocks` with `get_block/2` (chain_id, block_number) and `list_blocks/2` (chain_id, opts) with semantic cursor pagination (before: block_number, limit)
- [x] 2.3 Implement `Rexplorer.Transactions` with `get_transaction/2` (chain_id, hash), `get_full_transaction/2` (with preloaded associations), and `list_transactions/2` (chain_id, opts with optional address filter, before_block, before_index, limit)
- [x] 2.4 Implement `Rexplorer.Addresses` with `get_address/2` (chain_id, hash) and `get_address_overview/2` (with recent txs + transfers)
- [x] 2.5 Implement `Rexplorer.Search` with `query/2` (input, opts) that classifies input type (tx hash, block number, address) and returns results
- [x] 2.6 Write tests for all domain query modules with seeded test data
- [x] 2.7 Document all domain query modules with `@moduledoc` and `@doc`

## 3. Public API Controllers and Views

- [x] 3.1 Implement `RexplorerWeb.API.V1.ChainController` (index, show) and `ChainJSON` view
- [x] 3.2 Implement `RexplorerWeb.API.V1.BlockController` (index, show) and `BlockJSON` view. Index supports `?before=<block_number>&limit=<n>` pagination
- [x] 3.3 Implement `RexplorerWeb.API.V1.TransactionController` (index, show) and `TransactionJSON` view. Index supports `?address=<addr>&before_block=<n>&before_index=<i>&limit=<n>`
- [x] 3.4 Implement `RexplorerWeb.API.V1.OperationController` (index — nested under transaction) and `OperationJSON` view
- [x] 3.5 Implement `RexplorerWeb.API.V1.AddressController` (show) and `AddressJSON` view
- [x] 3.6 Implement `RexplorerWeb.API.V1.TokenTransferController` (index — nested under address) and `TokenTransferJSON` view
- [x] 3.7 Add routes for all public API controllers in the `:public_api` scope
- [x] 3.8 Write controller tests for all public API endpoints (happy path + error cases + pagination)
- [x] 3.9 Document public API response formats in each JSON view module

## 4. BFF Controllers and Views

- [x] 4.1 Implement `RexplorerWeb.Internal.TransactionDetailController` (show) — returns transaction + operations + transfers + logs + cross-chain links
- [x] 4.2 Implement `RexplorerWeb.Internal.AddressOverviewController` (show) — returns address + recent txs + recent transfers
- [x] 4.3 Implement `RexplorerWeb.Internal.HomeController` (show) — returns latest blocks + latest transactions for a chain
- [x] 4.4 Implement `RexplorerWeb.Internal.SearchController` (index) — classifies query and returns results with redirect hints
- [x] 4.5 Add routes for all BFF controllers in the `:internal_api` scope
- [x] 4.6 Write controller tests for all BFF endpoints

## 5. Phoenix Channels

- [x] 5.1 Create `RexplorerWeb.BlockChannel` that joins `blocks:<chain_slug>` and subscribes to PubSub topic `chain:<chain_id>:blocks`
- [x] 5.2 Create `RexplorerWeb.AddressChannel` that joins `address:<chain_slug>:<address_hash>` and subscribes to PubSub topics for that address
- [x] 5.3 Update `RexplorerWeb.UserSocket` to route channel topics
- [x] 5.4 Add PubSub broadcast to the indexer worker: after persisting a block, broadcast `{:new_block, block_summary}` on `chain:<chain_id>:blocks`
- [x] 5.5 Write channel tests (join, receive broadcasts)

## 6. Documentation

- [x] 6.1 Create `docs/api.md` documenting all public API endpoints with request/response examples
- [x] 6.2 Create `docs/workflows/api-request.md` with Mermaid sequence diagram showing request flow: client → router → plug (chain slug) → controller → domain query → DB → JSON view → response
- [x] 6.3 Create `docs/workflows/realtime-subscription.md` with Mermaid sequence diagram showing: client → WebSocket → channel join → PubSub subscribe → indexer broadcast → push to client

## 7. Final Verification

- [x] 7.1 Run full test suite: `mix test`
- [x] 7.2 Compile with `mix compile --warnings-as-errors`
- [x] 7.3 Manual smoke test: start server, query `/api/v1/chains`, verify JSON response
