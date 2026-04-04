## ADDED Requirements

### Requirement: Project setup
The system SHALL have a `frontend/` directory at the repository root containing a Vite + React + TypeScript project. It MUST include Tailwind CSS configured with dark mode (`class` strategy). The project MUST be buildable with `npm run build` and runnable in development with `npm run dev`.

#### Scenario: Development server starts
- **WHEN** `npm run dev` is run in the `frontend/` directory
- **THEN** the Vite dev server starts and proxies API requests to the Phoenix backend

#### Scenario: Production build
- **WHEN** `npm run build` is run
- **THEN** optimized static assets are generated in `frontend/dist/`

### Requirement: Makefile integration
The Makefile at the repository root MUST include targets: `frontend.install` (npm install), `frontend.dev` (start dev server), `frontend.build` (production build).

#### Scenario: Full project setup
- **WHEN** `make setup` is run
- **THEN** both Elixir deps and npm packages are installed

### Requirement: Routing structure
The system SHALL use React Router with the following route structure:
- `/` — landing page / chain selector
- `/:chain/` — chain home page
- `/:chain/blocks` — block list
- `/:chain/block/:number` — block detail
- `/:chain/tx/:hash` — transaction detail
- `/:chain/address/:hash` — address overview
- `*` — 404 not found

#### Scenario: Navigate to transaction
- **WHEN** the URL is `/ethereum/tx/0xabc...`
- **THEN** the transaction detail page is rendered for Ethereum chain with that hash

### Requirement: Layout with header
The system SHALL provide a layout wrapper applied to all pages. The header MUST contain: the rexplorer logo/name, a search bar, a chain switcher dropdown, and a dark mode toggle. The layout MUST be responsive.

#### Scenario: Header on every page
- **WHEN** any page is loaded
- **THEN** the header with search, chain switcher, and dark mode toggle is visible

### Requirement: API client configuration
The system SHALL provide an API client module that configures TanStack Query with the base URL for the Phoenix backend. In development, the Vite proxy MUST forward `/api/*` and `/internal/*` requests to `http://localhost:4000`.

#### Scenario: API call in development
- **WHEN** the frontend calls `/internal/chains/ethereum/home`
- **THEN** Vite proxies the request to the Phoenix backend on port 4000
