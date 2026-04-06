## 1. Shared EVM Base Module

- [x] 1.1 Create `Rexplorer.Chain.EVM` with `__using__` macro that injects default implementations for: `extract_operations/1`, `extract_token_transfers/1`, `block_fields/0`, `transaction_fields/0`, `bridge_contracts/0` — all marked `defoverridable`
- [x] 1.2 Move all shared helper functions from Ethereum adapter to `Rexplorer.Chain.EVM`: native transfer extraction, ERC-20 transfer extraction, `decode_address_topic/1`, `decode_uint256/1`
- [x] 1.3 Refactor `Rexplorer.Chain.Ethereum` to `use Rexplorer.Chain.EVM` and only define: `chain_id/0` (1), `chain_type/0` (:l1), `native_token/0` (ETH, 18), `poll_interval_ms/0` (12000)
- [x] 1.4 Run existing Ethereum adapter tests — all must pass unchanged
- [x] 1.5 Document `Rexplorer.Chain.EVM` with `@moduledoc` explaining how to use it for new adapters

## 2. OP Stack Module

- [x] 2.1 Create `Rexplorer.Chain.OPStack` with `__using__` macro that overrides `block_fields/0` to return `[{:l1_block_number, :integer}, {:sequence_number, :integer}]` and `transaction_fields/0` to return `[{:source_hash, :string}, {:mint, :integer}, {:is_system_tx, :boolean}]`
- [x] 2.2 Document `Rexplorer.Chain.OPStack` with `@moduledoc`

## 3. Chain Adapters

- [x] 3.1 Create `Rexplorer.Chain.Optimism` — `use EVM`, `use OPStack`, chain_id: 10, chain_type: :optimistic_rollup, native_token: {"ETH", 18}, poll_interval: 2000, bridge_contracts: [`0xbeb5fc579115071764c7423a4f12edde41f106ed`]
- [x] 3.2 Create `Rexplorer.Chain.Base` — `use EVM`, `use OPStack`, chain_id: 8453, chain_type: :optimistic_rollup, native_token: {"ETH", 18}, poll_interval: 2000, bridge_contracts: [`0x49048044d57e1c92a77f79988d21fa8faf74e97e`]
- [x] 3.3 Create `Rexplorer.Chain.BNB` — `use EVM`, chain_id: 56, chain_type: :sidechain, native_token: {"BNB", 18}, poll_interval: 3000
- [x] 3.4 Create `Rexplorer.Chain.Polygon` — `use EVM`, chain_id: 137, chain_type: :sidechain, native_token: {"POL", 18}, poll_interval: 2000

## 4. Configuration

- [x] 4.1 Update `config/config.exs` to register all five adapters in the Chain Registry
- [x] 4.2 Verify indexer chain config has RPC URLs for all five chains (placeholder URLs for non-Ethereum)

## 5. Tests

- [x] 5.1 Write tests for each new adapter: verify chain_id, chain_type, native_token, poll_interval_ms, block_fields, transaction_fields return expected values
- [x] 5.2 Write test for Optimism/Base block_fields and transaction_fields (OP Stack specific)
- [x] 5.3 Write test for registry: all five adapters registered, each resolvable by chain_id
- [x] 5.4 Verify `extract_operations` and `extract_token_transfers` work through EVM base for all adapters (call with sample tx data)

## 6. Documentation

- [x] 6.1 Update `docs/chain-adapters.md` with the new module hierarchy (EVM → OPStack → adapters) and updated Mermaid diagram
- [x] 6.2 Update `docs/architecture.md` supported chains table

## 7. Final Verification

- [x] 7.1 Run `mix test` — all tests pass
- [x] 7.2 Run `mix compile --warnings-as-errors`
