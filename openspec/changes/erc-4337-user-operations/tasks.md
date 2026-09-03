## 1. Data Model

- [x] 1.1 Create migration adding `op_extra` (`:map`, default `%{}`, null: false) to `operations`; verify `mix ecto.migrate` and `mix ecto.rollback` both run clean against the dev database
- [x] 1.2 Add the partial expression index `operations (chain_id, (op_extra->>'user_op_hash')) WHERE op_extra ? 'user_op_hash'` to the same migration; verify with `EXPLAIN` that a userOpHash lookup uses the index rather than a sequential scan
- [x] 1.3 Add `op_extra` to `Rexplorer.Schema.Operation` (field + changeset cast) and document the key set in the `@moduledoc`; verify an operation round-trips extras through `Repo.insert!` and reload

## 2. ABI Registry

- [x] 2.1 Register both `handleOps` signatures (v0.6 unpacked, v0.7/v0.8 packed) with param names `ops`, `beneficiary`; verify `lookup_selector/1` returns a distinct entry for each
- [x] 2.2 Register `execute(address,uint256,bytes)` and both `executeBatch` shapes with param names; verify each decodes a sample calldata into named params
- [x] 2.3 Register the `UserOperationEvent` event with its indexed flags; verify `lookup_event/1` resolves the topic0 and that a sample log decodes to userOpHash, sender, paymaster, success and actualGasCost
- [x] 2.4 Add a test asserting the computed selectors equal `0x1fad948c`, `0x765e827f`, `0xb61d27f6`, `0x18dfb3c7`, `0x47e1da2a` — the same guard used for `execTransaction` and `multicall`

## 3. ERC-4337 Unwrapper — detection and decoding

- [x] 3.1 Create `Rexplorer.Unwrapper.ERC4337` implementing the behaviour, matching both `handleOps` selectors; verify `matches?/2` is true for both shapes, false for `handleAggregatedOps`, a Safe tx and a plain transfer
- [x] 3.2 Decode the ops array for both tuple shapes into a normalized list of `%{sender, nonce, init_code, call_data, paymaster_and_data}`; verify with fixture calldata for a v0.6 bundle and a v0.7 bundle
- [x] 3.3 Extract paymaster from `paymasterAndData` and factory from `initCode` (leading 20 bytes, omitted when empty); verify sponsored, unsponsored and deploying UserOps produce the expected keys
- [x] 3.4 Implement the fallback path — undecodable calldata, empty ops array, or a raise returns `[]` so the registry falls back to a single `call`; verify with truncated and garbage calldata

## 4. ERC-4337 Unwrapper — fan-out and correlation

- [x] 4.1 Implement the account-execution lookup: `execute` → one operation at the inner target, both `executeBatch` shapes → one operation per inner call, unknown selector → one operation at the smart account with raw `callData`; verify each branch with fixture UserOps
- [x] 4.2 Assign `operation_index` sequentially across the whole transaction and stamp `user_op_index` per UserOperation; verify a two-UserOp bundle where the second batches two calls yields indexes 0,1,2 with user_op_index 0,1,1
- [x] 4.3 Filter transaction logs to `UserOperationEvent`, zip by position when counts match, and stamp `user_op_hash`, `paymaster`, `success`, `actual_gas_cost`; verify a three-op bundle gets three distinct hashes
- [x] 4.4 Skip correlation when counts mismatch or logs are absent, keeping calldata-derived extras; verify operations are still produced and no hash is attributed to the wrong UserOperation
- [x] 4.5 Stamp `entry_point` (tx `to_address`) and `entry_point_version` from the matched selector; verify both bundle fixtures carry the right version
- [x] 4.6 Write the failed-UserOp test: a bundle whose transaction succeeded but whose second event reports `success = false` marks only that UserOperation's operations unsuccessful
- [x] 4.7 Write the `@moduledoc` covering detection, both shapes, fan-out and correlation, with the unwrap flow as a Mermaid diagram

## 5. Unwrapper Registry

- [x] 5.1 Register `ERC4337` in `Rexplorer.Unwrapper.Registry` ahead of Safe and Multicall; verify a bundle routes to it while Safe and multicall transactions still route to theirs
- [x] 5.2 Document `:logs` as an optional key of the unwrapper's transaction map in the `Rexplorer.Unwrapper` behaviour docs; verify the Safe and Multicall unwrappers are unaffected by its presence
- [x] 5.3 Add registry tests for the bundle-with-logs, bundle-without-logs and raising-unwrapper cases; verify the last returns a single `call` operation

## 6. BlockProcessor

- [x] 6.1 Move log extraction ahead of operation extraction in the regular-transaction branch of `process_block/3` and pass the logs into the adapter's transaction map; verify existing block processor tests still pass unchanged
- [x] 6.2 Propagate `op_extra` from unwrapper output through `extract_operations/2` to the result map; verify a bundle fixture reaches the result with extras intact
- [x] 6.3 Confirm the frame path can pass its per-frame logs the same way; verify `frame_transaction_test.exs` still passes and a frame carrying a bundle unwraps
- [x] 6.4 Add a `process_block/3` test with a full bundle fixture (raw tx + receipt with UserOperationEvent logs); verify operations, logs and addresses all come out of one call
- [x] 6.5 Update the module's Mermaid diagram to show log extraction preceding operation extraction

## 7. Address Labels

- [x] 7.1 Create `Rexplorer.Labels` returning `{address, label}` pairs for EntryPoint (with version), paymaster, smart account sender and factory; verify pure-function tests for a sponsored bundle and a deploying bundle
- [x] 7.2 Merge labels into `BlockProcessor.discover_addresses/5`, preferring the labelled form on duplicates; verify a block where the same address appears plainly and in a role yields one labelled map
- [x] 7.3 Change the indexer worker's address upsert to fill `label` only where NULL (`conflict_target: [:chain_id, :hash]`, coalesce on update); verify an existing unlabelled address gains a label and an existing labelled one is untouched
- [x] 7.4 Add an end-to-end persistence test: index a bundle block twice and verify labels are identical after the second pass

## 8. Narration

- [x] 8.1 Add the `:user_operation` clause to `Pipeline.wrap_with_context/3`, reading `op_extra` for the paymaster, factory and success; verify a swap inside a sponsored UserOp narrates with the smart account as actor and a sponsorship clause
- [x] 8.2 Cover the variants with tests: unsponsored (no clause), deploying (deployment clause), failed (failure marker), unknown inner selector (falls back but keeps the AA framing)
- [x] 8.3 Bump `@decoder_version` so existing operations re-narrate; verify the decoder worker picks up rows with the older version

## 9. Search

- [x] 9.1 Add the userOpHash branch to `Rexplorer.Search.query/2` — 66-char hex missing on transactions is retried against `op_extra->>'user_op_hash'`, returning `:user_operation` with the parent transaction; verify hit, miss and chain-scoped cases
- [x] 9.2 Handle the new result type in the BFF search controller, returning a redirect to the parent transaction; verify a controller test for a userOpHash query
- [x] 9.3 Verify a transaction-hash search still issues one query (no regression from the fallback) using a test that asserts the transaction branch returns before the operations lookup

## 10. APIs

- [x] 10.1 Include `op_extra` in the BFF transaction detail's `op_json/1`; verify a controller test shows a bundle's operations carrying hash, index, entry point and paymaster
- [x] 10.2 Include the ERC-4337 fields in the public `/api/v1` operations endpoint and update the OpenAPI `Operation` schema to describe them as optional; verify `/api/openapi` renders and the response matches the schema
- [x] 10.3 Verify a non-AA transaction's operations are byte-identical to the previous response shape apart from an empty extras object

## 11. Frontend

- [x] 11.1 Extend `Operation` in `api/types.ts` with the `op_extra` fields; verify `make frontend.typecheck` passes
- [ ] 11.2 Build a `UserOpCard` explorer component — sender via `AddressDisplay`, status via `StatusBadge`, paymaster and deployment badges via `Badge`, copyable userOpHash, decoded actions list; verify it renders each variant against fixture props
- [x] 11.3 Group `data.operations` by `user_op_index` in `TxDetailPage` and render a UserOperations section for bundles; verify a batched UserOp shows as one card with two actions
- [ ] 11.4 Make the story hero AA-aware — describe the bundle from the user's point of view, and read as the single operation's story when the bundle holds one; verify against a one-op and a three-op fixture
- [x] 11.5 Keep advanced mode intact: raw operations list and decoded EntryPoint logs still shown; verify by toggling advanced on a bundle fixture
- [x] 11.6 Handle the `user_operation` search result type in the search UI so a userOpHash navigates to its transaction; verify by searching a known hash
- [ ] 11.7 Verify no regression on non-AA transactions: no UserOperations section, page identical to before

## 12. Documentation

- [x] 12.1 Add the ERC-4337 unwrapper section to `docs/unwrap-layer.md` — both EntryPoint shapes, the fan-out table, and how to add an account-execution selector
- [x] 12.2 Create `docs/workflows/user-operation-indexing.md` with a Mermaid sequence diagram from bundle ingestion through unwrapping, correlation, persistence and narration
- [x] 12.3 Create `docs/workflows/userop-hash-lookup.md` with a Mermaid sequence diagram of the search fallback resolving a userOpHash to its transaction page
- [x] 12.4 Update `docs/architecture.md` (operations gain `op_extra`; address labels) and `docs/api.md` (new operation fields, userOpHash search); verify the workflow tables in `README.md` list the two new diagrams
- [x] 12.5 Mark roadmap item 1 with this change name in `docs/roadmap.md`

## 13. Final Verification

- [x] 13.1 Run `make test` — all Elixir tests pass
- [x] 13.2 Run `mix compile --warnings-as-errors` and `mix format --check-formatted`
- [x] 13.3 Run `make frontend.typecheck` and `make frontend.build`
- [ ] 13.4 Index a real mainnet bundle end to end and verify the tx page shows one card per UserOperation with correct senders, paymaster badge and per-operation outcomes
- [x] 13.5 Verify a real sponsored UserOp's hash, pasted into search, lands on its transaction page
