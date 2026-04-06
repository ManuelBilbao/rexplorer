## Why

Rexplorer indexes blocks and stores operations, but every `decoded_summary` is null. Transactions display as raw calldata and hex values — no different from any other explorer. The decoder pipeline is what makes rexplorer *rexplorer*: it transforms raw on-chain data into human-readable stories like "Swapped 10 ETH for 25,000 USDC on Uniswap V3."

## What Changes

- **ABI registry** (`Rexplorer.Decoder.ABI`) — a built-in registry of curated ABI definitions for known protocols (ERC-20, Uniswap V2/V3, WETH, Aave V3). Decodes function selectors and calldata parameters using `ex_abi`.
- **Protocol interpreters** — modules that understand specific protocols and extract semantic meaning:
  - `Rexplorer.Decoder.Interpreter.ERC20` — transfer, approve
  - `Rexplorer.Decoder.Interpreter.UniswapV2` — swap
  - `Rexplorer.Decoder.Interpreter.UniswapV3` — swap (exactInput, exactOutput variants)
  - `Rexplorer.Decoder.Interpreter.WETH` — deposit (wrap), withdraw (unwrap)
  - `Rexplorer.Decoder.Interpreter.AaveV3` — supply, withdraw, borrow, repay
- **Narrator** (`Rexplorer.Decoder.Narrator`) — composes interpreter output into human-readable `decoded_summary` strings, formatting amounts with token symbols and decimals.
- **Decoder worker** (`Rexplorer.Decoder.Worker`) — an async GenServer that processes operations with `decoder_version IS NULL OR decoder_version < current_version`. Runs independently from the indexer. Supports both initial decode (new operations) and reprocessing (decoder upgrades).
- **Decoder pipeline** (`Rexplorer.Decoder.Pipeline`) — orchestrates the flow: ABI decode → interpret → narrate. Pure functions, easy to test.

## Non-goals

- **Unwrap layer** (Safe multisig, AA UserOps, Multicall) — follow-up change. v1 decodes the top-level call only.
- **Event/log decoding** — the `logs.decoded` JSONB field is not populated by this change.
- **Cross-chain link detection from decoded data** — deferred.
- **4byte.directory / external ABI sources** — built-in registry only for v1.
- **Contract verification / source code fetching** — deferred.

## Capabilities

### New Capabilities
- `abi-registry`: Built-in ABI definitions for known protocols, function selector lookup, calldata decoding
- `protocol-interpreters`: Semantic interpretation of decoded calls into structured actions (swap, transfer, deposit, etc.)
- `decoder-narrator`: Composition of structured actions into human-readable summary strings
- `decoder-worker`: Async background worker that processes operations and populates decoded_summary + decoder_version

### Modified Capabilities
*(none)*

## Impact

- **`apps/rexplorer/`** — new `Rexplorer.Decoder.*` modules (pipeline, ABI registry, interpreters, narrator, worker)
- **Dependencies** — `ex_abi` for ABI encoding/decoding
- **`apps/rexplorer_indexer/`** — no changes (decoder is independent)
- **Database** — no schema changes (decoder_summary and decoder_version fields already exist)
- **Token registry** — the narrator uses the `tokens` + `token_addresses` tables to resolve token symbols/decimals

### Architectural fit
The decoder pipeline lives in the core `rexplorer` app (not the indexer) because it's domain logic that may be called from multiple contexts: the async worker, a future on-demand decode API endpoint, or test tools. The worker runs alongside the indexer but is fully independent — it queries for unprocessed operations and decodes them in batches.
