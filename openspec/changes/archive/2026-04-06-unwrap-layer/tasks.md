## 1. ABI Registry Additions

- [x] 1.1 Add `execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)` to the ABI registry with param names: `to`, `value`, `data`, `operation`, `safeTxGas`, `baseGas`, `gasPrice`, `gasToken`, `refundReceiver`, `signatures`
- [x] 1.2 Add `multicall(bytes[])` and `multicall(uint256,bytes[])` to the ABI registry with param names: `data` and `deadline,data` respectively
- [x] 1.3 Verify selectors are correct: execTransaction=`0x6a761202`, multicall=`0xac9650d8`, multicall(uint256,bytes[])=`0x5ae401dc`

## 2. Unwrapper Behaviour and Registry

- [x] 2.1 Define `Rexplorer.Unwrapper` behaviour with callbacks: `matches?/2` (transaction, chain_id) and `unwrap/2` (transaction, chain_id) returning list of operation attrs
- [x] 2.2 Implement `Rexplorer.Unwrapper.Registry` with `unwrap/2` that iterates registered unwrappers (Safe, Multicall), returns first match, falls back to single `:call` operation
- [x] 2.3 Write tests for registry: Safe tx routed to Safe unwrapper, multicall routed to Multicall unwrapper, plain tx returns single call
- [x] 2.4 Document behaviour and registry

## 3. Safe Unwrapper

- [x] 3.1 Implement `Rexplorer.Unwrapper.Safe` — matches if input starts with `0x6a761202` (execTransaction selector). Uses ABI decode to extract inner `to`, `value`, `data`, `operation` params.
- [x] 3.2 Return single operation: type `:multisig_execution` (or `:delegate_call` if operation=1), `from_address` = Safe address (tx.to_address), `to_address` = inner target, `value` = inner value, `input` = inner calldata
- [x] 3.3 Handle edge cases: empty inner data, zero-value inner call, failed decode (return single :call fallback)
- [x] 3.4 Write tests with sample Safe execTransaction calldata: wrapping an ERC-20 transfer, wrapping a swap, delegatecall case, malformed data fallback
- [x] 3.5 Document Safe unwrapper

## 4. Multicall Unwrapper

- [x] 4.1 Implement `Rexplorer.Unwrapper.Multicall` — matches if input starts with `0xac9650d8` or `0x5ae401dc`. Uses ABI decode to extract the `bytes[]` array.
- [x] 4.2 For each inner call bytes, return an operation: type `:multicall_item`, `operation_index` sequential, `from_address` = tx sender, `to_address` = multicall contract (tx.to_address), `input` = inner calldata
- [x] 4.3 Handle edge cases: empty bytes array (fallback to single :call), single-item multicall
- [x] 4.4 Write tests with sample multicall calldata: 2-item multicall, 3-item multicall, empty multicall fallback, Uniswap V3 variant
- [x] 4.5 Document Multicall unwrapper

## 5. Update Chain Adapter

- [x] 5.1 Update `Rexplorer.Chain.Ethereum.extract_operations/1` to call `Rexplorer.Unwrapper.Registry.unwrap/2` instead of always returning a single `:call`
- [x] 5.2 Update Ethereum adapter tests to verify: plain tx still returns single call, Safe tx returns multisig_execution, multicall returns multiple multicall_items
- [x] 5.3 Ensure BlockProcessor correctly handles multiple operations per transaction (operation_index, tx_hash propagation)

## 6. Documentation

- [x] 6.1 Create `docs/unwrap-layer.md` with Mermaid diagram showing the unwrap flow and how to add a new unwrapper
- [x] 6.2 Update `docs/decoder-pipeline.md` to reference the unwrap layer as the second stage
- [x] 6.3 Update `docs/architecture.md` to include the unwrap layer in the system overview

## 7. Final Verification

- [x] 7.1 Run `mix test` — all tests pass
- [x] 7.2 Run `mix compile --warnings-as-errors`
- [x] 7.3 Verify with a real Safe transaction: operation_type is multisig_execution, decoder produces summary of the inner call
