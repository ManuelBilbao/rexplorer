## 1. Project Scaffold

- [x] 1.1 Create `frontend/` with Vite + React + TypeScript: `npm create vite@latest frontend -- --template react-ts`
- [x] 1.2 Install dependencies: `tailwindcss`, `@tanstack/react-query`, `react-router`, `phoenix` (channels client)
- [x] 1.3 Configure Tailwind CSS with dark mode (`class` strategy), custom color palette, and `globals.css` with Tailwind directives
- [x] 1.4 Configure Vite proxy: `/api/*`, `/internal/*`, `/socket` → `http://localhost:4000`
- [x] 1.5 Set up directory structure: `src/components/ui/`, `src/components/explorer/`, `src/components/layout/`, `src/pages/`, `src/hooks/`, `src/api/`, `src/lib/`
- [x] 1.6 Set up React Router with all routes in `App.tsx` (landing, home, blocks, block detail, tx detail, address, 404)
- [x] 1.7 Set up TanStack Query provider in `App.tsx`
- [x] 1.8 Add Makefile targets: `frontend.install`, `frontend.dev`, `frontend.build`
- [x] 1.9 Verify `make frontend.dev` starts the Vite dev server and `make frontend.build` produces `frontend/dist/`

## 2. API Client and Types

- [x] 2.1 Create `src/api/types.ts` with TypeScript interfaces for all API responses: Chain, Block, Transaction, Operation, TokenTransfer, Address, CrossChainLink, SearchResult, HomeData, TxDetail, AddressOverview
- [x] 2.2 Create `src/api/client.ts` with base fetch wrapper that handles JSON parsing and error responses
- [x] 2.3 Create `src/api/queries.ts` with TanStack Query hooks: `useChains`, `useBlock`, `useBlocks`, `useTransaction`, `useTxDetail`, `useTransactions`, `useAddress`, `useAddressOverview`, `useHomeData`, `useSearch`
- [x] 2.4 Create `src/lib/format.ts` with formatting utilities: `formatAddress` (truncate), `formatAmount` (decimal conversion + thousand separators), `formatGas`, `formatTimestamp`, `formatBlockNumber`

## 3. Component Library (ui/)

- [x] 3.1 Implement `Button` component with variants (primary, secondary, ghost, danger), sizes (sm, md, lg), loading state, dark mode
- [x] 3.2 Implement `DataTable` component with columns config, data rendering, loading skeleton, empty state, "Load more" footer
- [x] 3.3 Implement `Badge` component with color variants (green, red, yellow, blue, gray), dark mode
- [x] 3.4 Implement `Tabs` component with TabList and TabPanel, active state styling
- [x] 3.5 Implement `Skeleton` component with width/height/rounded props and pulse animation
- [x] 3.6 Implement `Modal` component with overlay, close on Escape/backdrop, focus trap
- [x] 3.7 Implement `Toast` component and `useToast` hook with success/error/info variants and auto-dismiss
- [x] 3.8 Implement `Tooltip` component with hover trigger and positioned content
- [x] 3.9 Implement `Dropdown` component with trigger, menu items, close on outside click/Escape

## 4. Explorer Components (explorer/)

- [x] 4.1 Implement `AddressDisplay` with truncation, copy button, optional label, link to address page
- [x] 4.2 Implement `TxHash` with truncation, copy button, link to transaction page
- [x] 4.3 Implement `TokenAmount` with decimal conversion, thousand separators, symbol display
- [x] 4.4 Implement `BlockNumber` with thousand separator formatting and link to block page
- [x] 4.5 Implement `TimeAgo` with relative time display and absolute time tooltip, periodic update
- [x] 4.6 Implement `StatusBadge` (Success/Failed/Pending with appropriate colors)
- [x] 4.7 Implement `ChainBadge` with chain name and color indicator
- [x] 4.8 Implement `CopyButton` with clipboard API and "Copied!" feedback
- [x] 4.9 Implement `SearchBar` with input, loading state, and navigation on result

## 5. Layout

- [x] 5.1 Implement `Header` with rexplorer logo/name, SearchBar, chain switcher Dropdown, dark mode toggle
- [x] 5.2 Implement `Footer` with minimal branding
- [x] 5.3 Implement `PageContainer` layout wrapper that applies Header + Footer + main content area
- [x] 5.4 Implement `useDarkMode` hook with localStorage persistence and system preference detection
- [x] 5.5 Implement `useChain` hook that reads `:chain` param from React Router and provides chain context

## 6. Pages

- [x] 6.1 Implement `LandingPage` — displays all chains from `useChains()`, links to `/:chain/`
- [x] 6.2 Implement `HomePage` — latest blocks + latest transactions from `useHomeData()`, real-time block updates via `useBlockSubscription`
- [x] 6.3 Implement `BlockListPage` — DataTable with blocks from `useBlocks()`, "Load more" pagination
- [x] 6.4 Implement `BlockDetailPage` — block header fields + transaction list from `useBlock()`
- [x] 6.5 Implement `TxDetailPage` — transaction summary, operations with decoded summaries, token transfers, logs, cross-chain links from `useTxDetail()`. Simple/Advanced toggle.
- [x] 6.6 Implement `AddressPage` — address metadata + recent transactions + recent token transfers from `useAddressOverview()`. Real-time updates via `useAddressSubscription`.
- [x] 6.7 Implement `NotFoundPage` — friendly 404 message

## 7. Real-time Hooks

- [x] 7.1 Implement `useSocket` hook — singleton Phoenix Socket connection at `/socket` with auto-reconnect
- [x] 7.2 Implement `useBlockSubscription(chainSlug)` — joins `blocks:<chain>`, returns latest block event, handles channel switch on chain change
- [x] 7.3 Implement `useAddressSubscription(chainSlug, addressHash)` — joins `address:<chain>:<hash>`, triggers toast on new activity

## 8. Documentation

- [x] 8.1 Create `frontend/README.md` documenting: setup, development workflow, directory structure, component library overview
- [x] 8.2 Create `docs/frontend.md` with Mermaid diagram showing data flow: React pages → TanStack Query → BFF API → Phoenix → DB, and WebSocket flow
- [x] 8.3 Update `docs/architecture.md` to include the frontend layer in the system overview

## 9. Final Verification

- [x] 9.1 Verify `make frontend.install && make frontend.build` succeeds with zero TypeScript errors
- [x] 9.2 Verify `make frontend.dev` starts and all pages render with loading states (no backend needed for skeleton UI)
- [x] 9.3 Verify dark mode toggle works and persists across page reload
- [x] 9.4 Run TypeScript type checking: `npx tsc --noEmit`
