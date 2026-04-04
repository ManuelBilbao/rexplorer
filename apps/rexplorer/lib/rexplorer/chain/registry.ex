defmodule Rexplorer.Chain.Registry do
  @moduledoc """
  Registry of available chain adapters.

  Maps chain IDs to their adapter modules, loaded from application configuration
  at startup. Provides lookup, listing, and filtering by enabled status.

  ## Configuration

      config :rexplorer, Rexplorer.Chain.Registry,
        adapters: [
          Rexplorer.Chain.Ethereum
        ]
  """

  use GenServer
  require Ecto.Query

  # Client API

  @doc "Starts the registry, loading adapters from application config."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the adapter module for the given chain ID.

  Returns `{:ok, module}` if found, `{:error, :unknown_chain}` otherwise.
  """
  def get_adapter(chain_id) do
    GenServer.call(__MODULE__, {:get_adapter, chain_id})
  end

  @doc "Returns all registered adapter modules."
  def list_adapters do
    GenServer.call(__MODULE__, :list_adapters)
  end

  @doc """
  Returns adapter modules for chains that are enabled in the database.

  Falls back to all adapters if the database is not available.
  """
  def enabled_adapters do
    GenServer.call(__MODULE__, :enabled_adapters)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    adapters = Keyword.get(opts, :adapters) || load_adapters_from_config()

    adapter_map =
      adapters
      |> Enum.map(fn mod -> {mod.chain_id(), mod} end)
      |> Map.new()

    {:ok, %{adapters: adapter_map}}
  end

  @impl true
  def handle_call({:get_adapter, chain_id}, _from, state) do
    case Map.fetch(state.adapters, chain_id) do
      {:ok, adapter} -> {:reply, {:ok, adapter}, state}
      :error -> {:reply, {:error, :unknown_chain}, state}
    end
  end

  @impl true
  def handle_call(:list_adapters, _from, state) do
    {:reply, Map.values(state.adapters), state}
  end

  @impl true
  def handle_call(:enabled_adapters, _from, state) do
    enabled =
      try do
        enabled_chain_ids =
          Rexplorer.Repo.all(
            Ecto.Query.from(c in Rexplorer.Schema.Chain,
              where: c.enabled == true,
              select: c.chain_id
            )
          )

        state.adapters
        |> Enum.filter(fn {chain_id, _mod} -> chain_id in enabled_chain_ids end)
        |> Enum.map(fn {_chain_id, mod} -> mod end)
      rescue
        _ -> Map.values(state.adapters)
      end

    {:reply, enabled, state}
  end

  defp load_adapters_from_config do
    Application.get_env(:rexplorer, __MODULE__, [])
    |> Keyword.get(:adapters, [])
  end
end
