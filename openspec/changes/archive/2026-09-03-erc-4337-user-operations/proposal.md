## Why

Rexplorer claims to be "Account Abstraction native from day one," but today an ERC-4337 bundle is the single worst-explained transaction in the explorer. A bundler calls `handleOps` on the EntryPoint, and the unwrap registry — which already knows how to peel Safe and Multicall — has no unwrapper for it, so the whole bundle collapses into one `:call` operation reading "Called 0x1fad948c on 0x0000000071727de22e5e9d8baf0edac6f37da032". Every real actor in that transaction is invisible: the smart accounts that actually authored the intents, the paymaster that paid for them, and the individual actions inside each UserOperation. The bundler EOA — the one address in the transaction with no user intent at all — is the only one shown as the sender.

`Schema.Operation` has carried a `:user_operation` type since the first migration and `core-data-model` already specifies that a bundle produces one operation per UserOp. Nothing produces them. This change makes the fourth wrapper pattern work like the other three, and gives the AA-specific facts (paymaster, userOpHash, EntryPoint version, sponsorship) somewhere to live and somewhere to be seen.

## What Changes

- **`Rexplorer.Unwrapper.ERC4337`** — a fourth unwrapper, detecting `handleOps` by selector for EntryPoint v0.6 (`UserOperation[]`) and v0.7/v0.8 (`PackedUserOperation[]`), decoding the ops array and emitting one or more operations per UserOperation.
- **Two-level unwrap for the account call** — a UserOp's `callData` is a call *to the smart account itself*, almost always `execute(dest,value,func)` or `executeBatch(...)`. The unwrapper peels that second layer so operations point at the real target: `execute` yields one operation, `executeBatch` fans out to one operation per inner call. All operations from the same UserOp share a `user_op_index` so they stay groupable.
- **UserOperationEvent correlation** — the EntryPoint emits one `UserOperationEvent` per UserOp, carrying userOpHash, sender, paymaster, success and actual gas cost. These are the authoritative values (a v0.7 paymaster address is otherwise buried in `paymasterAndData`), so the unwrapper reads the transaction's logs and zips them with the decoded ops by position. Calldata-only fallback when logs are unavailable.
- **`op_extra` JSONB on `operations`** — the AA facts have nowhere to live today. A `map` column mirroring `transactions.chain_extra` holds `user_op_hash`, `user_op_index`, `entry_point`, `entry_point_version`, `paymaster`, `factory`, `success` and `actual_gas_cost`, and stays available for the L2-lifecycle and cross-chain roadmap items.
- **Logs reach operation extraction** — `BlockProcessor` currently builds the adapter's transaction map from `from/to/value/input` only, and extracts operations *before* logs. Log extraction moves ahead of operation extraction and the map gains `:logs`. No existing unwrapper reads it.
- **Address role labels** — `Address.label` exists and nothing has ever written it. Indexing an AA bundle now labels the EntryPoint, the paymaster, each smart account sender, and the account factory, so those roles are visible everywhere an address is rendered.
- **Narration for `:user_operation`** — the pipeline's `wrap_with_context/3` learns the AA case: "Smart account 0x… swapped 10 ETH for 25,000 USDC on Uniswap V3 (gas paid by paymaster 0x…)".
- **Search by userOpHash** — a 66-char hex that is not a transaction hash is looked up against `op_extra->>'user_op_hash'` and resolves to the parent transaction.
- **API and UI** — the BFF transaction detail and the public operations endpoint expose `op_extra`; the tx detail page gains a UserOperations section listing each UserOp with its sender, paymaster badge, status and inner actions, replacing the bundler-centric hero for AA transactions.

## Non-goals

- **`handleAggregatedOps`** — BLS/aggregated bundles. The signature aggregator path is rare and has a different calldata shape; the unwrapper falls back to a single `:call` for it.
- **EntryPoint v0.5 and earlier** — no longer meaningfully used on the target chains.
- **Historical reprocessing** — as with the Safe/Multicall unwrappers, only newly indexed blocks get UserOp operations. Bundles indexed before this change keep their single `:call`.
- **Paymaster policy decoding** — the paymaster *address* is extracted; the rest of `paymasterAndData` (ERC-7677 policy data, validity windows, token rates) is not decoded.
- **Factory creation arguments** — the factory address is extracted from `initCode`; the account-creation calldata that follows it is not decoded, so "which owner key deployed this account" is out of scope.
- **A dedicated `/userops` listing endpoint** — UserOps are reachable through their parent transaction and by userOpHash search. A first-class paginated UserOp API is a follow-up.
- **Gas sponsorship analytics** — per-paymaster spend, top sponsors, deposit tracking on the EntryPoint.
- **Wallet-vendor account variants** — `execute`/`executeBatch` covers the reference SimpleAccount shape used by most deployed accounts; Kernel, Biconomy and Safe4337Module custom execution selectors are additive follow-ups to the same lookup table.

## Capabilities

### New Capabilities
- `erc4337-unwrapper`: `handleOps` detection across EntryPoint versions, UserOperation decoding, account-level `execute`/`executeBatch` fan-out, `UserOperationEvent` correlation, and paymaster/factory extraction
- `address-labels`: deterministic role labels written to `addresses.label` at index time, seeded with the ERC-4337 roles (EntryPoint, paymaster, smart account, factory)

### Modified Capabilities
- `core-data-model`: `operations` gains an `op_extra` JSONB column; the bundle scenario under "Operation abstraction" now accounts for batched UserOps producing more than one operation
- `unwrap-registry`: the unwrapper behaviour's transaction map may carry `:logs`; the registry gains the ERC-4337 unwrapper ahead of Safe and Multicall
- `block-processing`: logs are extracted before operations and passed to the adapter; `op_extra` is propagated; discovered addresses carry labels
- `abi-registry`: `handleOps` (both EntryPoint shapes), `execute`, `executeBatch` (both shapes) and the `UserOperationEvent` event are registered
- `decoder-narrator`: `:user_operation` operations narrate with the smart account as actor and a sponsorship clause when a paymaster is present
- `domain-queries`: the search module classifies a 66-char hex that misses on transactions as a possible userOpHash
- `bff-api`: transaction detail returns `op_extra` per operation; search resolves a userOpHash to its transaction
- `public-api`: the operations endpoint returns the UserOp fields
- `frontend-pages`: the transaction detail page renders a UserOperations section and an AA-aware hero

## Impact

- **`apps/rexplorer/`** — new `Rexplorer.Unwrapper.ERC4337` and `Rexplorer.Labels`; ABI registry additions; `Schema.Operation` gains `op_extra`; `Decoder.Pipeline` narration; `Rexplorer.Search` gains a userOpHash branch
- **`apps/rexplorer_indexer/`** — `BlockProcessor` reorders log/operation extraction, passes logs into the adapter, and attaches labels to discovered addresses; the worker's address upsert switches from `on_conflict: :nothing` to filling a null label
- **`apps/rexplorer_web/`** — BFF transaction detail and search controllers, public operations controller, OpenAPI schemas
- **`frontend/`** — `TxDetailPage` UserOperations section, a `UserOpCard` explorer component, `api/types.ts`
- **Database** — one migration: `op_extra` JSONB on `operations` plus an expression index on `(chain_id, (op_extra->>'user_op_hash'))` for search
- **Chain extensibility** — the unwrapper is chain-agnostic and lives in core, so every EVM adapter gets AA unwrapping for free the moment its chain has an EntryPoint deployed; nothing is added to the adapter behaviour

### Architectural fit
This is the AA half of the unwrap layer, the second stage of the four-layer pipeline (ABI decode → **Unwrap** → Interpret → Narrate). It follows the shape the Safe and Multicall unwrappers established — selector-based detection, chain-agnostic module in core, one registry entry — and extends it in exactly two ways: the unwrapper may read the transaction's logs, and an operation may carry structured extras alongside its narration. Both extensions are what the cross-chain journey and L2 lifecycle roadmap items will need next.
