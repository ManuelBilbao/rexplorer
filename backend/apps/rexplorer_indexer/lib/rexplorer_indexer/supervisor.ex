defmodule RexplorerIndexer.ChainSupervisor do
  @moduledoc """
  Supervises per-chain indexer workers.

  On startup, queries `Rexplorer.Chain.Registry.enabled_adapters/0` and starts
  one `RexplorerIndexer.Worker` for each enabled chain that has an RPC URL
  configured. Workers are supervised with `:one_for_one` strategy so that a
  crash in one chain's indexer does not affect others.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = build_worker_specs()
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 60)
  end

  defp build_worker_specs do
    chain_config = Application.get_env(:rexplorer_indexer, :chains, %{})

    Rexplorer.Chain.Registry.enabled_adapters()
    |> Enum.filter(fn adapter ->
      chain_id = adapter.chain_id()
      config = Map.get(chain_config, chain_id, %{})

      if config[:rpc_url] do
        true
      else
        Logger.warning("[Indexer] No RPC URL configured for chain #{chain_id}, skipping")
        false
      end
    end)
    |> Enum.map(fn adapter ->
      chain_id = adapter.chain_id()
      config = Map.get(chain_config, chain_id)

      Supervisor.child_spec(
        {RexplorerIndexer.Worker,
         adapter: adapter,
         rpc_url: config[:rpc_url],
         name: {:global, {RexplorerIndexer.Worker, chain_id}}},
        id: {RexplorerIndexer.Worker, chain_id}
      )
    end)
  end
end
