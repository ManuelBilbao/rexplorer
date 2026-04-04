# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :rexplorer,
  ecto_repos: [Rexplorer.Repo]

config :rexplorer, Rexplorer.Chain.Registry,
  adapters: [
    Rexplorer.Chain.Ethereum
  ]

# Chain indexer configuration
# RPC URLs are per-chain, keyed by EIP-155 chain ID
config :rexplorer_indexer,
  chains: %{
    1 => %{rpc_url: "http://localhost:8545"},
    10 => %{rpc_url: "http://localhost:9545"},
    8453 => %{rpc_url: "http://localhost:9546"},
    56 => %{rpc_url: "http://localhost:8546"},
    137 => %{rpc_url: "http://localhost:8547"}
  }

config :rexplorer_web,
  ecto_repos: [Rexplorer.Repo],
  generators: [context_app: :rexplorer]

# Configures the endpoint
config :rexplorer_web, RexplorerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RexplorerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Rexplorer.PubSub,
  live_view: [signing_salt: "kJTE4nl2"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
