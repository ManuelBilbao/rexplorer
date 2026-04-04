.PHONY: help setup deps compile test clean db.create db.migrate db.reset db.seed server console lint format

help: ## Show this help
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Setup ---

setup: deps frontend.install db.setup ## Initial project setup (deps + database + frontend)

deps: ## Fetch and compile dependencies
	mix deps.get
	mix deps.compile

# --- Build ---

compile: ## Compile all apps
	mix compile

compile.warnings: ## Compile with warnings as errors
	mix compile --warnings-as-errors

format: ## Format all code
	mix format

format.check: ## Check code formatting
	mix format --check-formatted

# --- Database ---

db.create: ## Create the database
	mix ecto.create

db.migrate: ## Run pending migrations
	mix ecto.migrate

db.rollback: ## Rollback the last migration
	mix ecto.rollback

db.seed: ## Run seed data
	mix run apps/rexplorer/priv/repo/seeds.exs

db.setup: db.create db.migrate db.seed ## Create, migrate, and seed the database

db.reset: ## Drop, create, migrate, and seed the database
	mix ecto.reset

db.reset.test: ## Reset the test database
	MIX_ENV=test mix ecto.drop --quiet
	MIX_ENV=test mix ecto.create --quiet
	MIX_ENV=test mix ecto.migrate --quiet

# --- Test ---

test: ## Run all tests
	mix test

test.watch: ## Run tests on file changes
	mix test --listen-on-stdin

test.cover: ## Run tests with coverage
	mix test --cover

test.failed: ## Re-run only failed tests
	mix test --failed

# --- Server ---

server: ## Start the Phoenix server
	mix phx.server

console: ## Start an interactive console
	iex -S mix phx.server

# --- Frontend ---

frontend.install: ## Install frontend dependencies
	cd frontend && npm install

frontend.dev: ## Start frontend dev server
	cd frontend && npm run dev

frontend.build: ## Build frontend for production
	cd frontend && npm run build

frontend.typecheck: ## Run TypeScript type checking
	cd frontend && npx tsc --noEmit

# --- Clean ---

clean: ## Clean build artifacts
	mix clean
	rm -rf _build

clean.deps: ## Clean dependencies
	mix deps.clean --all
	rm -rf deps

clean.all: clean clean.deps ## Clean everything (build + deps)
