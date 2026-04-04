# Rexplorer Frontend

React + TypeScript + Vite frontend for the rexplorer blockchain explorer.

## Setup

```bash
make frontend.install    # or: cd frontend && npm install
```

## Development

```bash
make frontend.dev        # Vite dev server on :5173 (proxies API to Phoenix :4000)
make server              # Phoenix backend (separate terminal)
```

## Build

```bash
make frontend.build      # Production build → frontend/dist/
make frontend.typecheck  # TypeScript type checking
```

## Stack

- **React 19** + **TypeScript** + **Vite**
- **Tailwind CSS** with dark mode
- **TanStack Query** for data fetching/caching
- **React Router** for routing
- **phoenix.js** for WebSocket channels

## Directory Structure

```
src/
├── api/                  # Client, types, TanStack Query hooks
├── components/
│   ├── ui/               # Component library (Button, DataTable, Badge, Tabs, etc.)
│   ├── explorer/         # Blockchain-specific (AddressDisplay, TxHash, TokenAmount, etc.)
│   └── layout/           # Header, Footer, PageContainer
├── hooks/                # useChain, useDarkMode, useSocket, useBlockSubscription, etc.
├── lib/                  # Formatting utilities
├── pages/                # Route-level components
└── styles/               # Tailwind globals + custom CSS
```

## Routes

| Path | Page | API |
|------|------|-----|
| `/` | Chain selector | `/api/v1/chains` |
| `/:chain/` | Home | `/internal/chains/:chain/home` |
| `/:chain/blocks` | Block list | `/api/v1/chains/:chain/blocks` |
| `/:chain/block/:number` | Block detail | `/api/v1/chains/:chain/blocks/:number` |
| `/:chain/tx/:hash` | Transaction detail | `/internal/chains/:chain/transactions/:hash` |
| `/:chain/address/:hash` | Address overview | `/internal/chains/:chain/addresses/:hash` |
