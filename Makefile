.PHONY: help setup deps compile test clean db.create db.migrate db.reset db.seed server console lint format

BACKEND := backend
FRONTEND := frontend

help: ## Show this help
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Setup ---

setup: deps frontend.install db.setup ## Initial project setup (deps + database + frontend)

deps: ## Fetch and compile dependencies
	cd $(BACKEND) && mix deps.get
	cd $(BACKEND) && mix deps.compile

# --- Build ---

compile: ## Compile all apps
	cd $(BACKEND) && mix compile

compile.warnings: ## Compile with warnings as errors
	cd $(BACKEND) && mix compile --warnings-as-errors

format: ## Format all code
	cd $(BACKEND) && mix format

format.check: ## Check code formatting
	cd $(BACKEND) && mix format --check-formatted

# --- Database ---

db.create: ## Create the database
	cd $(BACKEND) && mix ecto.create

db.migrate: ## Run pending migrations
	cd $(BACKEND) && mix ecto.migrate

db.rollback: ## Rollback the last migration
	cd $(BACKEND) && mix ecto.rollback

db.seed: ## Run seed data
	cd $(BACKEND) && mix run apps/rexplorer/priv/repo/seeds.exs

db.setup: db.create db.migrate db.seed ## Create, migrate, and seed the database

db.reset: ## Drop, create, migrate, and seed the database
	cd $(BACKEND) && mix ecto.reset

db.reset.test: ## Reset the test database
	cd $(BACKEND) && MIX_ENV=test mix ecto.drop --quiet
	cd $(BACKEND) && MIX_ENV=test mix ecto.create --quiet
	cd $(BACKEND) && MIX_ENV=test mix ecto.migrate --quiet

# --- Test ---

test: ## Run all tests
	cd $(BACKEND) && mix test

test.watch: ## Run tests on file changes
	cd $(BACKEND) && mix test --listen-on-stdin

test.cover: ## Run tests with coverage
	cd $(BACKEND) && mix test --cover

test.failed: ## Re-run only failed tests
	cd $(BACKEND) && mix test --failed

# --- Server ---

server: ## Start the Phoenix server
	cd $(BACKEND) && mix phx.server

console: ## Start an interactive console
	cd $(BACKEND) && iex -S mix phx.server

# --- Frontend ---

frontend.install: ## Install frontend dependencies
	cd $(FRONTEND) && npm install

frontend.dev: ## Start frontend dev server
	cd $(FRONTEND) && npm run dev

frontend.build: ## Build frontend for production
	cd $(FRONTEND) && npm run build

frontend.typecheck: ## Run TypeScript type checking
	cd $(FRONTEND) && npx tsc --noEmit

# --- Clean ---

clean: ## Clean build artifacts
	cd $(BACKEND) && mix clean
	rm -rf $(BACKEND)/_build

clean.deps: ## Clean dependencies
	cd $(BACKEND) && mix deps.clean --all
	rm -rf $(BACKEND)/deps

clean.all: clean clean.deps ## Clean everything (build + deps)
