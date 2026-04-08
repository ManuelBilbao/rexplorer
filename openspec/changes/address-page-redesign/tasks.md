## 1. Types & API Hooks

- [x] 1.1 Add `balance_wei: string | null` to `Address` interface in `frontend/src/api/types.ts`
- [x] 1.2 Add `BalanceHistoryEntry` type (`block_number`, `balance_wei`, `timestamp`) to types
- [x] 1.3 Add `useBalanceHistory(chain, hash)` React Query hook fetching `/internal/chains/:slug/addresses/:hash/balance-history`
- [x] 1.4 Add `useAddressTokenTransfers(chain, hash, before?)` React Query hook fetching `/api/v1/chains/:slug/addresses/:hash/token-transfers` with cursor pagination

## 2. BalanceChart Component

- [x] 2.1 Create `frontend/src/components/explorer/BalanceChart.tsx` — SVG area chart component accepting `data: {timestamp: string, balance_wei: string}[]`
- [x] 2.2 Implement SVG path generation: map timestamps to X, balances to Y, render filled area + stroke line
- [x] 2.3 Add Y-axis min/max labels and X-axis date labels
- [x] 2.4 Handle edge cases: empty data (show "No balance history"), single point, all-zero balances
- [x] 2.5 Style with Tailwind CSS variables (`rex-primary` for the line, `rex-primary/10` for the fill area)

## 3. Address Page Redesign

- [x] 3.1 Rewrite `AddressPage.tsx` with new layout structure: header → stat cards → chart → tabbed lists
- [x] 3.2 Implement stat cards section: Balance (formatted with native token symbol), Last Active (from most recent tx), First Seen (from `first_seen_at`)
- [x] 3.3 Integrate BalanceChart component with `useBalanceHistory` data, with skeleton loading state
- [x] 3.4 Implement tabbed layout using existing `Tabs` UI component for Transactions and Token Transfers
- [x] 3.5 Implement "Load more" pagination for transactions tab using `useTransactions` with address filter and cursor
- [x] 3.6 Implement "Load more" pagination for token transfers tab using `useAddressTokenTransfers` with cursor
- [x] 3.7 Add loading skeletons for stat cards and list sections

## 4. Documentation

- [x] 4.1 Document BalanceChart component props and usage in JSDoc comments
- [x] 4.2 Document data flow with Mermaid diagram in AddressPage module comment
