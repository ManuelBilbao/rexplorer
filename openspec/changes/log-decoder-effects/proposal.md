## Why

The decoder pipeline decodes operation *intent* (what the user asked to do), but the transaction detail page doesn't show what actually *happened* as a result. Event logs are stored raw (topics + data) and the `logs.decoded` JSONB field is always null. Users see "Transferred 27 USDC" as the operation summary but can't see the full chain of effects: approvals set, swaps executed, tokens moved, liquidity added. This is the gap between "what was called" and "what changed."

## What Changes

- **Event signature registry** — extend the ABI registry to include known event signatures (Transfer, Approval, Swap, Supply, Withdraw, etc.) and decode event logs by topic0
- **Log decoder** — a module that takes raw log data (topics + data) and produces structured decoded output: event name, decoded parameters with human-readable values
- **Populate `logs.decoded`** — the decoder worker processes logs alongside operations, writing decoded event data into the existing `decoded` JSONB column
- **Frontend "Effects" section** — a new section on the transaction detail page that composes token_transfers + decoded logs into a human-readable timeline of what happened
- **Known event signatures** — ERC-20 (Transfer, Approval), Uniswap V2/V3 (Swap, Mint, Burn), Aave V3 (Supply, Withdraw, Borrow, Repay, Liquidation), WETH (Deposit, Withdrawal)

## Non-goals

- Decoding ALL events — only known protocol events from the built-in registry
- Storing decoded events in a separate table — using the existing `logs.decoded` JSONB field
- Event-based cross-chain link detection — deferred

## Capabilities

### New Capabilities
- `event-decoder`: Event signature registry, log decoding, and `logs.decoded` population
- `effects-view`: Frontend "Effects" section on transaction detail page

### Modified Capabilities
- `decoder-worker`: Extended to process logs in addition to operations

## Impact

- **`apps/rexplorer/`** — new event decoder module, extended ABI registry with event signatures, updated decoder worker
- **`frontend/`** — new Effects section on TxDetailPage
- **Database** — no schema changes (`logs.decoded` JSONB already exists)
- **BFF API** — transaction detail endpoint already returns logs with decoded field

### Architectural fit
This extends the decoder pipeline with a parallel path: operations decode calldata (intent), logs decode events (effects). Both feed into the same transaction detail view, giving users the full picture.
