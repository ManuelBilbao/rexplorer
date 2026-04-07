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
    Rexplorer.Chain.Ethereum,
    Rexplorer.Chain.Optimism,
    Rexplorer.Chain.Base,
    Rexplorer.Chain.BNB,
    Rexplorer.Chain.Polygon
  ]

# Ethrex L2 chains (config-driven, no code changes needed per deployment)
# Example:
# config :rexplorer, :ethrex_chains, [
#   %{chain_id: 12345, name: "My Ethrex L2", rpc_url: "http://localhost:1729",
#     poll_interval_ms: 3000, bridge_address: "0x..."}
# ]
config :rexplorer, :ethrex_chains, [
    %{chain_id: 65536999, name: "Ethrex L2 Dev", rpc_url: "http://localhost:1729", poll_interval_ms: 5000, bridge_address: "0x15ec25bec93b63a3c4b9ec56b2c78466a617f9a3"}
]

# Chain indexer configuration
# RPC URLs are per-chain, keyed by EIP-155 chain ID
config :rexplorer_indexer,
  chains: %{
    1 => %{rpc_url: "http://ts.mainnet.internal.lambdaclass.com:8545/"},
    10 => %{rpc_url: "http://localhost:9545"},
    8453 => %{rpc_url: "http://localhost:9546"},
    56 => %{rpc_url: "https://rpc.ankr.com/bsc/f5103a1046566351899224d25cc33c39cf436edc57e64416e3da1605ed62b816"},
    137 => %{rpc_url: "http://localhost:8547"},
    65536999 => %{rpc_url: "http://localhost:1729"}
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
