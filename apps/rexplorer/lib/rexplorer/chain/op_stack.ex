defmodule Rexplorer.Chain.OPStack do
  @moduledoc """
  Shared module for OP Stack (Optimism, Base) chain adapters.

  Layers on top of `Rexplorer.Chain.EVM` to add L2-specific block and
  transaction fields. OP Stack chains have deposit transactions (type 0x7E/126)
  with additional metadata.

  ## Usage

      defmodule Rexplorer.Chain.Optimism do
        use Rexplorer.Chain.EVM
        use Rexplorer.Chain.OPStack

        @impl true
        def chain_id, do: 10
        # ... other chain-specific metadata
      end
  """

  defmacro __using__(_opts) do
    quote do
      @impl true
      def block_fields do
        [
          {:l1_block_number, :integer},
          {:sequence_number, :integer}
        ]
      end

      @impl true
      def transaction_fields do
        [
          {:source_hash, :string},
          {:mint, :integer},
          {:is_system_tx, :boolean}
        ]
      end

      defoverridable block_fields: 0, transaction_fields: 0
    end
  end
end
