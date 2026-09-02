defmodule Rexplorer.Repo do
  use Ecto.Repo,
    otp_app: :rexplorer,
    adapter: Ecto.Adapters.Postgres
end
