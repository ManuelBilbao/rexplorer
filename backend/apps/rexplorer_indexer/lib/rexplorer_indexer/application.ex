defmodule RexplorerIndexer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RexplorerIndexer.ChainSupervisor
    ]

    opts = [strategy: :one_for_one, name: RexplorerIndexer.AppSupervisor]
    Supervisor.start_link(children, opts)
  end
end
