defmodule Rexplorer.Chain.Ethrex do
  @moduledoc """
  Stack module for Ethrex ZK rollup L2 chains.

  Unlike OPStack adapters (one hardcoded module per chain), Ethrex chains are
  config-driven. Each deployment is defined in application config and a dynamic
  adapter module is created at startup.

  ## How it works

  The `__using__` macro accepts a config map and injects adapter callbacks
  parameterized with that config. The Registry uses `Module.create/3` to
  generate a unique module per Ethrex chain.

  ## Config format

      %{
        chain_id: 12345,
        name: "MyEthrex",
        rpc_url: "http://localhost:1729",
        poll_interval_ms: 3000,
        bridge_address: "0x..."
      }

  ## Transaction types

  Ethrex has two custom transaction types:
  - **Privileged (0x7E / 126)**: L1→L2 deposit transactions, no signature
  - **FeeToken (0x7D / 125)**: Like EIP-1559 but gas paid in an ERC-20 token
  """

  defmacro __using__(config) do
    quote do
      use Rexplorer.Chain.EVM

      @ethrex_config unquote(config)

      @impl true
      def chain_id, do: @ethrex_config[:chain_id]

      @impl true
      def chain_type, do: :zk_rollup

      @impl true
      def native_token, do: {"ETH", 18}

      @impl true
      def poll_interval_ms, do: @ethrex_config[:poll_interval_ms] || 3_000

      @impl true
      def bridge_contracts do
        case @ethrex_config[:bridge_address] do
          nil -> []
          addr -> [addr]
        end
      end

      @impl true
      def supports_traces?, do: true

      @impl true
      def block_fields do
        [{:batch_number, :integer}]
      end

      @impl true
      def transaction_fields do
        [
          {:is_privileged, :boolean},
          {:l1_origin_hash, :string},
          {:fee_token, :string}
        ]
      end
    end
  end

  @doc """
  Dynamically creates an adapter module for an Ethrex chain config.

  Returns the module name atom.
  """
  def create_adapter(config) do
    chain_id = config[:chain_id] || config.chain_id
    module_name = :"Elixir.Rexplorer.Chain.Ethrex_#{chain_id}"

    unless Code.ensure_loaded?(module_name) do
      contents =
        quote do
          use Rexplorer.Chain.EVM
          use Rexplorer.Chain.Ethrex, unquote(Macro.escape(config))
        end

      Module.create(module_name, contents, Macro.Env.location(__ENV__))
    end

    module_name
  end
end
