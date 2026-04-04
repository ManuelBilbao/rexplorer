## Why

Rexplorer has a public REST API, a BFF API, and Phoenix Channels — but no way for users to interact with the data. This change adds the React frontend that consumes those APIs and presents the explorer experience. The frontend is the face of rexplorer: where the "human-readable transaction stories" philosophy becomes visible, where the regular user discovers what happened on-chain, and where dark mode soothes late-night debugging sessions.

## What Changes

- **React + TypeScript + Vite project** at `frontend/` in the repository root, with Tailwind CSS and dark mode support
- **Custom component library** (`ui/`) — rexplorer's own buttons, tables, badges, tabs, modals, skeletons, tooltips, toasts. No third-party component framework. Full ownership of the visual identity.
- **Explorer-specific components** (`explorer/`) — `AddressDisplay`, `TxHash`, `TokenAmount`, `BlockNumber`, `TimeAgo`, `StatusBadge`, `ChainBadge`, `CopyButton`, `SearchBar`. The design language of rexplorer.
- **Core pages** — Home (latest blocks + txs), block list, block detail, transaction detail (with operations + transfers + logs), address overview (with recent activity)
- **Layout** — Header with search bar + chain switcher + dark mode toggle, responsive design
- **Data layer** — TanStack Query for API data fetching/caching, custom hooks for BFF endpoints, phoenix.js for real-time WebSocket subscriptions (new blocks, address activity)
- **Routing** — React Router with chain-scoped routes (`/:chain/tx/:hash`, `/:chain/block/:number`, etc.)
- **Makefile integration** — `make frontend.dev`, `make frontend.build`, `make frontend.install`

## Non-goals

- Server-side rendering / SEO prerendering (follow-up change)
- Contract interaction pages (read/write)
- Token pages
- Trace explorer / internal transaction visualization
- Advanced search filters / query builder
- User accounts / saved addresses / watchlists
- Mobile-specific responsive optimizations (basic responsive only)

## Capabilities

### New Capabilities
- `component-library`: Custom reusable UI components (Button, Table, Badge, Tabs, Modal, Skeleton, Tooltip, Toast, Dropdown) built with Tailwind CSS and dark mode support
- `explorer-components`: Blockchain-specific display components (AddressDisplay, TxHash, TokenAmount, BlockNumber, TimeAgo, StatusBadge, ChainBadge, CopyButton, SearchBar)
- `frontend-pages`: Core explorer pages consuming the BFF and public APIs — home, block list, block detail, transaction detail, address overview
- `frontend-realtime`: WebSocket integration via phoenix.js for live block notifications and address activity
- `frontend-scaffold`: Vite + React + TypeScript project setup, Tailwind config, routing, layout, dark mode, Makefile targets

### Modified Capabilities
*(none)*

## Impact

- **`frontend/`** — entirely new directory at the repository root
- **`Makefile`** — new targets for frontend development
- **`config/dev.exs`** — may need proxy config for Vite dev server → Phoenix API during development
- **Dependencies** — Node.js + npm required for frontend development
- **No Elixir code changes** — the frontend consumes existing APIs without modification

### Architectural fit
This is the presentation layer of the two-tier API architecture. The frontend talks exclusively to `/internal/*` (BFF) for page data and to Phoenix Channels for real-time updates. The public API (`/api/v1/*`) remains for external developers. The separation established in the web-api change is what makes this clean — the frontend can evolve its data needs via the BFF without touching the public API contract.
