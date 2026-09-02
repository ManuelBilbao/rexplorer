import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# Database connection.
#
# Inside the Nix dev shell PGHOST points at a project-local Unix socket
# directory (.pg-socket), so we connect over that socket as the current OS
# user. Outside Nix we fall back to a conventional TCP postgres/postgres.
db_connection =
  case System.get_env("PGHOST") do
    nil ->
      [hostname: "localhost", username: "postgres", password: "postgres"]

    socket_dir ->
      [socket_dir: socket_dir, username: System.get_env("PGUSER") || System.get_env("USER")]
  end

config :rexplorer,
       Rexplorer.Repo,
       [
         database: "rexplorer_test#{System.get_env("MIX_TEST_PARTITION")}",
         pool: Ecto.Adapters.SQL.Sandbox,
         pool_size: System.schedulers_online() * 2
       ] ++ db_connection

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rexplorer_web, RexplorerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5BUlErFHdSO1rLoczisZqqMq69GEjwOULohfTxKrAOrW+HN7ocUCFfo24fFlF8f5",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
