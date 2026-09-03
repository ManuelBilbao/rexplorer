# Roadmap

What is planned, in priority order. This is the file to check for what to do
next.

Status is `in progress` (a change is being implemented), `next` (agreed as the
next piece of work), `planned` (agreed, not started) or `idea` (not decided
yet). When work on an item starts it becomes an
OpenSpec change — write the change name in the last column so the item can be
traced to its proposal, design, specs and tasks.

| # | Item | What it needs | Status | Change |
|---|------|---------------|--------|--------|
| 1 | ERC-4337 UserOps | An unwrapper for `handleOps` that emits one operation per UserOp; paymaster and smart-wallet labels. `Schema.Operation` already has the `user_operation` type. | in progress | [`erc-4337-user-operations`](../openspec/changes/erc-4337-user-operations/) |
| 2 | Historical backfill | The indexer only follows the chain head, so there is no past data. Needs a backward worker and per-chain progress tracking. | planned | — |
| 3 | Reorg recovery | The worker detects a reorg and halts. Needs to roll back the affected blocks and resume. | planned | — |
| 4 | Cross-chain journeys | Nothing writes `CrossChainLink` today. Needs a producer that matches deposit and withdrawal events across chains. | planned | — |
| 5 | L2 lifecycle stages | Batches are tracked, proved and finalized are not. Needs an adapter callback per stage and the stage shown on the tx page. | planned | — |
| 6 | Wider ABI coverage | Selectors come from a hardcoded list, so unknown calls show raw hex. Needs per-contract ABIs and a lookup for unknown selectors. | idea | — |
| 7 | Progressive disclosure | A user/dev mode toggle so raw fields stay reachable without cluttering the default view. | idea | — |
| 8 | Scale work | Query benchmarks, missing indexes and a load test against the target of millions of daily pageviews. | idea | — |
| 9 | MEV visibility | Bundle and sandwich detection. Explicitly deferred until the items above are done. | idea | — |

## Done

Shipped work, with the full record in `openspec/changes/archive/`.

| Change | What it added |
|--------|---------------|
| [`project-scaffold-and-core-data-model`](../openspec/changes/archive/2026-04-04-project-scaffold-and-core-data-model/) | Umbrella apps, Ecto schemas |
| [`live-chain-indexer`](../openspec/changes/archive/2026-04-04-live-chain-indexer/) | Per-chain workers following the head |
| [`web-api`](../openspec/changes/archive/2026-04-04-web-api/) | Public `/api/v1` and BFF `/internal` |
| [`react-frontend`](../openspec/changes/archive/2026-04-04-react-frontend/) | React SPA, pages, real-time hooks |
| [`decoder-pipeline`](../openspec/changes/archive/2026-04-04-decoder-pipeline/) | ABI decode, interpret, narrate |
| [`chain-adapters`](../openspec/changes/archive/2026-04-06-chain-adapters/) | Optimism, Base, BNB, Polygon |
| [`log-decoder-effects`](../openspec/changes/archive/2026-04-06-log-decoder-effects/) | Event decoding, Effects section |
| [`unwrap-layer`](../openspec/changes/archive/2026-04-06-unwrap-layer/) | Safe and Multicall unwrappers |
| [`ethrex-l2-adapter`](../openspec/changes/archive/2026-04-07-ethrex-l2-adapter/) | Ethrex chains, batch tracking |
| [`balance-tracking`](../openspec/changes/archive/2026-04-08-balance-tracking/) | Native balances from traces |
| [`internal-transactions`](../openspec/changes/archive/2026-04-08-internal-transactions/) | Internal txs from traces |
| [`address-page-redesign`](../openspec/changes/archive/2026-04-08-address-page-redesign/) | Balance, chart, tabbed pagination |
| [`frame-transactions`](../openspec/changes/archive/2026-04-08-frame-transactions/) | EIP-8141 frames |
| [`adopt-ui-components`](../openspec/changes/archive/2026-04-09-adopt-ui-components/) | Component library across all pages |
