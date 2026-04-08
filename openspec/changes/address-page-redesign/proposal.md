## Why

The address page currently shows only a hash, a contract badge, and raw lists of recent transactions and token transfers. There is no balance display, no historical chart, and no structured overview. With the balance-tracking backend now serving `balance_wei` on addresses and a `/balance-history` endpoint, the frontend needs to surface this data. Balance is the #1 thing users look for on an address page — without it, Rexplorer feels incomplete. Additionally, the current 25-item transaction and token transfer lists have no pagination, cutting off history for active addresses.

## What Changes

- Redesign the address page layout with stat cards (Balance, Last Active, First Seen) at the top
- Add a balance history area chart rendered as hand-rolled SVG (no external chart library)
- Add `balance_wei` to the frontend `Address` type and display it formatted with the chain's native token symbol
- Add a `useBalanceHistory` React Query hook to fetch `/internal/chains/:slug/addresses/:hash/balance-history`
- Reorganize transactions and token transfers into a tabbed layout using the existing `Tabs` UI component
- Add cursor-based pagination ("Load more") to both transaction and token transfer lists within the address page
- Derive "Last Active" from the most recent transaction timestamp (no backend change needed)

## Non-goals

- **Fiat conversion** — no USD/EUR display; just native token amounts
- **Real-time balance updates** — WebSocket-driven live balance refresh is a future enhancement
- **Token balance display** — ERC-20/721/1155 balances are out of scope (only native token)
- **Chart interactivity** — no tooltips, zoom, or time-range selectors in this iteration

## Capabilities

### New Capabilities
- `address-page`: Frontend address page layout, stat cards, balance chart, tabbed transaction/transfer sections with cursor-based pagination

### Modified Capabilities
- `frontend-pages`: Address page component is being redesigned with new layout and data requirements

## Impact

- **Frontend only** — no backend changes; the BFF API already serves paginated transactions (`Rexplorer.Addresses.get_address_overview`) and token transfers (`Rexplorer.Addresses.list_token_transfers`) with cursor support, and the balance history endpoint exists
- `frontend/src/api/types.ts` — `Address` interface gains `balance_wei` field; new `BalanceHistoryEntry` type
- `frontend/src/api/queries.ts` — new `useBalanceHistory` hook; update address transaction/transfer queries for pagination
- `frontend/src/pages/AddressPage.tsx` — full rewrite
- New component: `frontend/src/components/explorer/BalanceChart.tsx`
- This change builds on the balance-tracking backend shipped in the previous commit and completes the user-facing story for address balances within the Rexplorer architecture
