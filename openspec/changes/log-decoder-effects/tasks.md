## 1. Event Signature Registry

- [x] 1.1 Add event signature definitions to the ABI registry: ERC-20 (Transfer, Approval), Uniswap V2 Swap, Uniswap V3 Swap, Aave V3 (Supply, Withdraw, Borrow, Repay), WETH (Deposit, Withdrawal)
- [x] 1.2 Implement `Rexplorer.Decoder.ABI.lookup_event/1` that takes a 32-byte topic0 and returns the event definition (name, param names, param types, indexed flags)
- [x] 1.3 Write tests for event lookup: known topic0 returns definition, unknown returns nil
- [x] 1.4 Document event registry additions

## 2. Event Decoder Module

- [x] 2.1 Implement `Rexplorer.Decoder.EventDecoder.decode_log/2` that takes a log struct and token_cache, decodes the event by topic0, extracts indexed params from topics and non-indexed from data, and returns `%{event_name: string, params: map, summary: string}` or `nil` for unknown events
- [x] 2.2 Implement event-specific summary formatting: Transfer ("Transfer 1,000 USDC from X to Y"), Approval ("Approval: X approved Y for Z USDC"), Swap ("Swap on Uniswap V3: 1.0 WETH for 3,247 USDC"), Aave events, WETH events
- [x] 2.3 Write tests for EventDecoder: decode Transfer event, decode Swap event, unknown event returns nil, handle events with missing/malformed data
- [x] 2.4 Document EventDecoder module

## 3. Extend Decoder Worker

- [x] 3.1 Update `Rexplorer.Decoder.Worker` to load logs for each transaction in the batch (join operations → transactions → logs)
- [x] 3.2 After processing operations, iterate transaction logs and call `EventDecoder.decode_log/2` for each
- [x] 3.3 Batch update `logs.decoded` JSONB for decoded logs (set to decoded map) — skip logs that already have decoded populated
- [x] 3.4 Write tests for extended worker: processes logs alongside operations, skips already-decoded logs, handles decode failures gracefully

## 4. Frontend Effects Section

- [x] 4.1 Create `EffectsSection` component that takes token_transfers and logs (with decoded) and renders a unified timeline
- [x] 4.2 Implement deduplication: filter out decoded Transfer logs that match an existing token_transfer (same from, to, amount)
- [x] 4.3 Render token transfers as "↓/↑ amount symbol from → to" entries
- [x] 4.4 Render decoded non-Transfer events using their `summary` field
- [x] 4.5 Add EffectsSection to TxDetailPage between Operations and the existing Token Transfers/Logs sections
- [x] 4.6 Handle empty state: "No decoded effects" when no token transfers and no decoded logs

## 5. Documentation

- [x] 5.1 Update `docs/decoder-pipeline.md` to include event decoding flow and how to add new event signatures
- [x] 5.2 Create `docs/workflows/effects-composition.md` with Mermaid diagram showing how the frontend composes the Effects view from token_transfers + decoded logs

## 6. Final Verification

- [x] 6.1 Run `mix test` — all tests pass
- [x] 6.2 Run `mix compile --warnings-as-errors`
- [x] 6.3 Run `make frontend.typecheck && make frontend.build`
- [x] 6.4 Verify with a real indexed transaction: log.decoded is populated, Effects section renders on frontend
