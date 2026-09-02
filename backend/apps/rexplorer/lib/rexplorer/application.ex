defmodule Rexplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Rexplorer.Repo,
      {DNSCluster, query: Application.get_env(:rexplorer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rexplorer.PubSub},
      Rexplorer.Chain.Registry,
      Rexplorer.Decoder.ABI,
      Rexplorer.Decoder.Worker
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Rexplorer.Supervisor)
  end
end
