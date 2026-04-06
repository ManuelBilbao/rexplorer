## Why

Rexplorer can only index Ethereum mainnet. The adapter system is in place, the behaviour is defined, and the indexer works — but only one chain has an adapter. This change adds adapters for Optimism, Base, BNB Smart Chain, and Polygon, enabling rexplorer to index all five target chains. It also extracts the shared EVM logic into a reusable base module to eliminate code duplication.

## What Changes

- **Shared EVM base module** (`Rexplorer.Chain.EVM`) — extracts the common logic from the Ethereum adapter: `extract_operations/1` (unwrapper delegation), `extract_token_transfers/1` (native + ERC-20 parsing), and all helper functions. All chain adapters `use` this module and only override chain-specific metadata.
- **OP Stack shared module** (`Rexplorer.Chain.OPStack`) — shared logic for Optimism and Base: deposit transaction detection (type 0x7E/126), `chain_extra` fields (`sourceHash`, `mint`, `isSystemTx` on transactions; `l1BlockNumber`, `sequenceNumber` on blocks), and OP Stack bridge contract addresses.
- **Optimism adapter** (`Rexplorer.Chain.Optimism`) — chain_id: 10, uses EVM + OPStack, Optimism-specific bridge addresses.
- **Base adapter** (`Rexplorer.Chain.Base`) — chain_id: 8453, uses EVM + OPStack, Base-specific bridge addresses.
- **BNB adapter** (`Rexplorer.Chain.BNB`) — chain_id: 56, uses EVM, 3s poll interval, BNB native token.
- **Polygon adapter** (`Rexplorer.Chain.Polygon`) — chain_id: 137, uses EVM, 2s poll interval, POL native token.
- **Registry updated** — all five adapters registered in config.

## Non-goals

- Cross-chain link detection logic (just bridge contract addresses for future use)
- Chain-specific protocol interpreters (Velodrome on OP, PancakeSwap on BNB, etc.)
- Ethrex L2 adapter (deferred until Ethrex L2 spec stabilizes)

## Capabilities

### New Capabilities
- `evm-base-module`: Shared EVM adapter logic extracted from Ethereum adapter
- `op-stack-adapters`: OP Stack shared module + Optimism and Base adapters with deposit tx handling
- `sidechain-adapters`: BNB Smart Chain and Polygon adapters

### Modified Capabilities
- `chain-adapter`: Ethereum adapter refactored to use the shared EVM base module; registry updated with all five adapters

## Impact

- **`apps/rexplorer/lib/rexplorer/chain/`** — new modules: `evm.ex`, `op_stack.ex`, `optimism.ex`, `base.ex`, `bnb.ex`, `polygon.ex`. Refactored: `ethereum.ex`.
- **`config/config.exs`** — registry updated with all adapters
- **No database changes** — `chain_extra` JSONB already supports arbitrary fields
- **Seeds** — already include all five chains

### Architectural fit
This completes the multi-chain foundation. Each chain implements the adapter behaviour with minimal code (10-30 lines), delegating shared logic to the EVM base and optionally the OP Stack module. The indexer can now start workers for all five chains — each with correct poll intervals, native tokens, and L2-specific field extraction.
