# Every target runs inside the Nix dev shell, so the only host requirement is
# Nix with flakes enabled. `nix develop` also brings up the project-local
# Postgres (socket in .pg-socket) via the flake's shellHook.
NIX := nix develop --command bash -c

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

# ── Environment ──────────────────────────────────────────────────────

.PHONY: shell
shell: ## Enter an interactive Nix dev shell
	nix develop

# ── Services ─────────────────────────────────────────────────────────

.PHONY: services.start services.stop services.status pg.start pg.stop pg.status

services.start: pg.start ## Start local services (Postgres)

services.stop: pg.stop ## Stop local services

services.status: pg.status ## Show local service status

pg.start: ## Start the project-local Postgres
	$(NIX) "mkdir -p .pg-socket && pg_ctl status -D .pg-data >/dev/null 2>&1 || pg_ctl start -D .pg-data -l .pg-data/postgres.log -o \"-k $$PWD/.pg-socket -c listen_addresses=\""

pg.stop: ## Stop the project-local Postgres
	$(NIX) "pg_ctl stop -D .pg-data 2>/dev/null || true"

pg.status: ## Show Postgres status
	$(NIX) "pg_ctl status -D .pg-data || true"

# ── Setup ────────────────────────────────────────────────────────────

.PHONY: setup deps frontend.install

setup: deps frontend.install db.setup ## Initial project setup (deps + database + frontend)

deps: ## Fetch and compile Elixir dependencies
	$(NIX) "cd backend && mix local.hex --force && mix local.rebar --force && mix deps.get && mix deps.compile"

frontend.install: ## Install frontend dependencies
	# CI=true lets pnpm purge a stale node_modules (e.g. after a Node version
	# bump) without prompting — targets run non-interactively under $(NIX).
	$(NIX) "cd frontend && CI=true pnpm install --frozen-lockfile"

# ── Build ────────────────────────────────────────────────────────────

.PHONY: compile compile.warnings format format.check

compile: ## Compile all apps
	$(NIX) "cd backend && mix compile"

compile.warnings: ## Compile with warnings as errors
	$(NIX) "cd backend && mix compile --warnings-as-errors"

format: ## Format all code
	$(NIX) "cd backend && mix format"

format.check: ## Check code formatting
	$(NIX) "cd backend && mix format --check-formatted"

# ── Database ─────────────────────────────────────────────────────────

.PHONY: db.create db.migrate db.rollback db.seed db.setup db.reset db.reset.test

db.create: ## Create the database
	$(NIX) "cd backend && mix ecto.create"

db.migrate: ## Run pending migrations
	$(NIX) "cd backend && mix ecto.migrate"

db.rollback: ## Rollback the last migration
	$(NIX) "cd backend && mix ecto.rollback"

db.seed: ## Run seed data
	$(NIX) "cd backend && mix run apps/rexplorer/priv/repo/seeds.exs"

db.setup: db.create db.migrate db.seed ## Create, migrate, and seed the database

db.reset: ## Drop, create, migrate, and seed the database
	$(NIX) "cd backend && mix ecto.reset"

db.reset.test: ## Reset the test database
	$(NIX) "cd backend && MIX_ENV=test mix ecto.drop --quiet && MIX_ENV=test mix ecto.create --quiet && MIX_ENV=test mix ecto.migrate --quiet"

# ── Test ─────────────────────────────────────────────────────────────

.PHONY: test test.watch test.cover test.failed

test: ## Run all tests
	$(NIX) "cd backend && mix test"

test.watch: ## Run tests on file changes
	$(NIX) "cd backend && mix test --listen-on-stdin"

test.cover: ## Run tests with coverage
	$(NIX) "cd backend && mix test --cover"

test.failed: ## Re-run only failed tests
	$(NIX) "cd backend && mix test --failed"

# ── Server ───────────────────────────────────────────────────────────

.PHONY: server console

server: ## Start the Phoenix server
	$(NIX) "cd backend && mix phx.server"

console: ## Start an interactive console
	nix develop --command bash -c "cd backend && iex -S mix phx.server"

# ── Frontend ─────────────────────────────────────────────────────────

.PHONY: frontend.dev frontend.build frontend.typecheck frontend.lint

frontend.dev: ## Start frontend dev server
	$(NIX) "cd frontend && pnpm run dev"

frontend.build: ## Build frontend for production
	$(NIX) "cd frontend && pnpm run build"

frontend.typecheck: ## Run TypeScript type checking
	$(NIX) "cd frontend && pnpm exec tsc --noEmit"

frontend.lint: ## Lint the frontend
	$(NIX) "cd frontend && pnpm run lint"

# ── Nix builds ───────────────────────────────────────────────────────

.PHONY: nix.build nix.build.web nix.build.indexer nix.build.frontend nix.check nix.update nix.hash.mix nix.hash.pnpm

nix.build: nix.build.web nix.build.indexer nix.build.frontend ## Build all release artifacts

nix.build.web: ## Build the rexplorer_web release
	nix build .#rexplorer-web --print-build-logs

nix.build.indexer: ## Build the rexplorer_indexer release
	nix build .#rexplorer-indexer --print-build-logs

nix.build.frontend: ## Build the frontend static bundle
	nix build .#rexplorer-frontend --print-build-logs

nix.check: ## Evaluate the flake
	nix flake check --all-systems

nix.update: ## Update flake inputs
	nix flake update

nix.hash.mix: ## Print the correct mix deps hash (paste into nix/packages.nix)
	@h=$$(nix build .#rexplorer-web 2>&1 | awk '/got:/ {print $$2}' | tail -1); \
	if [ -n "$$h" ]; then echo "$$h"; \
	else echo "no mismatch — the hash in nix/packages.nix is already correct"; fi

nix.hash.pnpm: ## Print the correct pnpm deps hash (paste into nix/packages.nix)
	@h=$$(nix build .#rexplorer-frontend 2>&1 | awk '/got:/ {print $$2}' | tail -1); \
	if [ -n "$$h" ]; then echo "$$h"; \
	else echo "no mismatch — the hash in nix/packages.nix is already correct"; fi

# ── Clean ────────────────────────────────────────────────────────────

.PHONY: clean clean.deps clean.all

clean: ## Clean build artifacts
	$(NIX) "cd backend && mix clean"
	rm -rf backend/_build result result-*

clean.deps: ## Clean dependencies
	$(NIX) "cd backend && mix deps.clean --all"
	rm -rf backend/deps frontend/node_modules

clean.all: clean clean.deps ## Clean everything (build + deps)
