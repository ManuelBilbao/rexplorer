## Why

Today every transaction produces exactly one `:call` operation, even when it's a Safe multisig executing an inner call or a Uniswap multicall batching multiple swaps. The user sees "Called execTransaction on 0x7a25..." instead of "Safe multisig executed: Swap 10 ETH for 25,000 USDC on Uniswap V3." The unwrap layer peels wrapper contracts to reveal the actual user intents inside, producing multiple operations per transaction with correct `from_address` attribution.

## What Changes

- **Unwrapper behaviour and registry** (`Rexplorer.Unwrapper`) — a module pattern mirroring the interpreter registry. Each unwrapper detects a wrapper pattern and returns the inner operations.
- **Safe unwrapper** (`Rexplorer.Unwrapper.Safe`) — detects `execTransaction` calls (selector `0x6a761202`), extracts the inner call (to, value, data), and returns a `:multisig_execution` operation with `from_address` set to the Safe address.
- **Multicall unwrapper** (`Rexplorer.Unwrapper.Multicall`) — detects `multicall(bytes[])` and `multicall(uint256,bytes[])` calls, extracts each inner call, and returns `:multicall_item` operations.
- **Updated chain adapter** — `extract_operations/1` in the Ethereum adapter calls the unwrapper registry instead of always returning a single `:call` operation. Falls back to a single `:call` for non-wrapped transactions.
- **ABI registry additions** — `execTransaction` and `multicall` function signatures added to the registry for calldata decoding.

## Non-goals

- **ERC-4337 Account Abstraction** (`handleOps`) — deferred to a follow-up change
- **Recursive unwrapping** (multicall containing Safe execution) — single-level unwrap only for v1
- **Historical reprocessing** — only newly indexed blocks get unwrapped operations. Existing single-call operations remain until a reindexing mechanism is built.
- **DSProxy, Timelock, Permit2** — deferred

## Capabilities

### New Capabilities
- `unwrap-registry`: Unwrapper behaviour, registry, and fallback logic for detecting and unwrapping wrapper contract patterns
- `safe-unwrapper`: Safe multisig `execTransaction` unwrapping into `:multisig_execution` operations
- `multicall-unwrapper`: Multicall unwrapping into `:multicall_item` operations

### Modified Capabilities
- `chain-adapter`: `extract_operations/1` updated to call the unwrapper registry

## Impact

- **`apps/rexplorer/`** — new `Rexplorer.Unwrapper.*` modules, updated ABI registry, updated Ethereum adapter
- **No database changes** — operation types `:multisig_execution` and `:multicall_item` already exist in the enum
- **Decoder pipeline** — no changes needed; it already processes each operation independently
- **Frontend** — already displays operation types and decoded summaries; no changes needed

### Architectural fit
The unwrap layer sits between the raw transaction and the operations table. It runs at index time inside `extract_operations/1`. The decoder pipeline then processes each unwrapped operation independently, producing per-operation summaries. This is the second layer of the original four-layer pipeline: ABI decode → **Unwrap** → Interpret → Narrate.
