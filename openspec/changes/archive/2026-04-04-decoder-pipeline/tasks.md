## 1. Dependencies and Setup

- [x] 1.1 Add `ex_abi` dependency to `apps/rexplorer/mix.exs` and run `mix deps.get`
- [x] 1.2 Create `priv/abis/` directory in the rexplorer app for ABI JSON files
- [x] 1.3 Add ABI JSON files for: ERC-20 (transfer, transferFrom, approve), Uniswap V2 Router (swap functions), Uniswap V3 SwapRouter (exactInput variants), WETH (deposit, withdraw), Aave V3 Pool (supply, withdraw, borrow, repay)
- [x] 1.4 Seed common tokens in `priv/repo/seeds.exs`: ETH (native), USDC, USDT, DAI, WETH with addresses for Ethereum mainnet

## 2. ABI Registry

- [x] 2.1 Implement `Rexplorer.Decoder.ABI` module with ETS-based registry. Load ABI definitions from `priv/abis/` JSON files at startup. Provide `lookup_selector/1`, `decode_calldata/2`, and `decode/1`
- [x] 2.2 Add ABI registry to the core app supervision tree (initialize ETS table on start)
- [x] 2.3 Write tests for ABI registry: known selector lookup, unknown selector returns nil, calldata decoding for ERC-20 transfer, calldata decoding for Uniswap swap
- [x] 2.4 Document ABI module with `@moduledoc` and `@doc`

## 3. Action Struct and Interpreter Behaviour

- [x] 3.1 Define `Rexplorer.Decoder.Action` struct with fields: `type` (atom), `protocol` (string), `params` (map)
- [x] 3.2 Define `Rexplorer.Decoder.Interpreter` behaviour with callbacks: `matches?/3` (to_address, decoded, chain_id) and `interpret/3` (decoded, tx_context, chain_id)
- [x] 3.3 Implement `Rexplorer.Decoder.Interpreter.Registry` with `interpret/3` that iterates interpreters in order, returning first match or `{:error, :no_interpreter}`

## 4. Protocol Interpreters

- [x] 4.1 Implement `Rexplorer.Decoder.Interpreter.ERC20` — matches any address calling transfer/transferFrom/approve, returns :transfer, :transfer_from, :approve actions
- [x] 4.2 Implement `Rexplorer.Decoder.Interpreter.UniswapV2` — matches V2 router addresses per chain, interprets swap functions as :swap actions with token path
- [x] 4.3 Implement `Rexplorer.Decoder.Interpreter.UniswapV3` — matches V3 router addresses per chain, interprets exactInput/exactOutput variants as :swap actions
- [x] 4.4 Implement `Rexplorer.Decoder.Interpreter.WETH` — matches known WETH addresses, interprets deposit as :wrap and withdraw as :unwrap
- [x] 4.5 Implement `Rexplorer.Decoder.Interpreter.AaveV3` — matches Aave V3 Pool addresses, interprets supply/withdraw/borrow/repay as corresponding action types
- [x] 4.6 Write tests for each interpreter with decoded call fixtures
- [x] 4.7 Write test for interpreter registry routing (correct interpreter selected, fallback for unknown)

## 5. Narrator

- [x] 5.1 Implement `Rexplorer.Decoder.Narrator.narrate/2` that takes an Action and chain_id, resolves token symbols, formats amounts, and returns a human-readable string
- [x] 5.2 Implement token resolution helper that queries token_addresses + tokens tables, with per-batch cache
- [x] 5.3 Implement amount formatting (divide by 10^decimals, thousand separators, trim trailing zeros)
- [x] 5.4 Implement fallback narration for unknown actions (use function name or raw selector)
- [x] 5.5 Write tests for narrator: swap narration, transfer narration, wrap/unwrap, unknown token fallback, unknown function fallback
- [x] 5.6 Document Narrator module

## 6. Pipeline

- [x] 6.1 Implement `Rexplorer.Decoder.Pipeline.decode_operation/2` that takes an operation (with input, to_address, value, chain_id) and returns `{:ok, summary_string}` or `{:error, reason}`. Orchestrates: ABI decode → interpret → narrate
- [x] 6.2 Define `@decoder_version` constant (start at 1)
- [x] 6.3 Write tests for full pipeline: ERC-20 transfer end-to-end, Uniswap swap end-to-end, unknown calldata fallback
- [x] 6.4 Document Pipeline module

## 7. Decoder Worker

- [x] 7.1 Implement `Rexplorer.Decoder.Worker` GenServer with poll loop: query undecoded operations (batch of 100), run pipeline, batch update decoded_summary + decoder_version
- [x] 7.2 Implement catch-up logic: if batch was full (100 ops), immediately process next batch; otherwise wait 5 seconds
- [x] 7.3 Implement graceful failure: catch decode errors per-operation, set decoder_version but leave decoded_summary nil, log warning, continue batch
- [x] 7.4 Add Decoder Worker to the core app supervision tree
- [x] 7.5 Write tests for worker: processes undecoded operations, skips already-decoded, handles decode failures gracefully

## 8. Documentation

- [x] 8.1 Create `docs/decoder-pipeline.md` with Mermaid diagram showing the full pipeline flow and how to add a new protocol interpreter
- [x] 8.2 Create `docs/workflows/decode-operation.md` with Mermaid sequence diagram: Worker → Pipeline → ABI → Interpreter → Narrator → DB update
- [x] 8.3 Update `docs/architecture.md` to include the decoder pipeline in the system overview

## 9. Final Verification

- [x] 9.1 Run full test suite: `mix test`
- [x] 9.2 Compile with `mix compile --warnings-as-errors`
- [x] 9.3 Verify decoder worker starts and processes test data (insert a mock operation with known ERC-20 transfer calldata, verify decoded_summary is populated)
