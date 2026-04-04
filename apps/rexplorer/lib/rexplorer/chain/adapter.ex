defmodule Rexplorer.Chain.Adapter do
  @moduledoc """
  Behaviour defining the contract that each chain implementation must fulfill.

  Every supported blockchain (Ethereum, Optimism, Base, etc.) implements this
  behaviour. The adapter provides chain-specific metadata, field definitions,
  and logic for extracting operations from transactions.

  ## Implementing a new chain adapter

      defmodule Rexplorer.Chain.Optimism do
        @behaviour Rexplorer.Chain.Adapter

        @impl true
        def chain_id, do: 10

        @impl true
        def chain_type, do: :optimistic_rollup

        @impl true
        def native_token, do: {"ETH", 18}

        @impl true
        def block_fields do
          [{:l1_block_number, :integer}, {:sequence_number, :integer}]
        end

        # ... remaining callbacks
      end
  """

  @doc """
  Returns the EIP-155 chain ID for this network.

  Must be a positive integer matching the chain's on-chain configuration
  (e.g., 1 for Ethereum mainnet, 10 for Optimism, 8453 for Base).
  """
  @callback chain_id() :: pos_integer()

  @doc """
  Returns the chain architecture type.

  Used to determine which features and UI elements are relevant
  (e.g., L2 lifecycle tracking only applies to rollups).
  """
  @callback chain_type() :: :l1 | :optimistic_rollup | :zk_rollup | :sidechain

  @doc """
  Returns the native token symbol and decimal places as a `{symbol, decimals}` tuple.

  For example: `{"ETH", 18}` for Ethereum, `{"BNB", 18}` for BNB Chain,
  `{"MATIC", 18}` for Polygon.
  """
  @callback native_token() :: {String.t(), non_neg_integer()}

  @doc """
  Returns a list of chain-specific field definitions for the blocks `chain_extra` JSONB column.

  Each entry is a `{field_name, type}` tuple describing what additional data
  this chain stores on blocks. Returns an empty list if the chain has no
  block-level extensions.

  Example for Optimism: `[{:l1_block_number, :integer}, {:sequence_number, :integer}]`
  """
  @callback block_fields() :: [{atom(), atom()}]

  @doc """
  Returns a list of chain-specific field definitions for the transactions `chain_extra` JSONB column.

  Same format as `block_fields/0` but for transaction-level extensions.
  Example for L2 deposits: `[{:l1_origin_tx_hash, :string}, {:deposit_nonce, :integer}]`
  """
  @callback transaction_fields() :: [{atom(), atom()}]

  @doc """
  Extracts operations (user intents) from a transaction.

  Given a transaction map with decoded data, returns a list of operation maps.
  Each operation map should include at minimum:
  - `:operation_type` — one of `:call`, `:user_operation`, `:multisig_execution`, `:multicall_item`, `:delegate_call`
  - `:operation_index` — zero-based index within the transaction
  - `:from_address` — the logical sender of the operation
  - `:to_address` — the target address
  - `:value` — the value transferred
  - `:input` — the calldata

  For simple EOA transactions, this returns a single `call` operation.
  For AA bundles, Safe multisigs, or multicalls, this returns multiple operations.
  """
  @callback extract_operations(transaction :: map()) :: [map()]

  @doc """
  Returns a list of known bridge contract addresses for this chain.

  Used by the cross-chain link detection system to identify bridge
  deposits and withdrawals. Returns an empty list if the chain has
  no native bridge contracts (e.g., Ethereum L1).
  """
  @callback bridge_contracts() :: [String.t()]

  @doc """
  Returns the recommended polling interval in milliseconds for live indexing.

  This should match the chain's typical block time. For example:
  - Ethereum mainnet: 12_000 (12 seconds)
  - Optimism/Base: 2_000 (2 seconds)
  - BNB Chain: 3_000 (3 seconds)
  """
  @callback poll_interval_ms() :: pos_integer()

  @doc """
  Extracts token transfers from a transaction.

  Given a transaction map containing `:value`, `:from_address`, `:to_address`,
  and `:logs` (list of log maps), returns a list of token transfer attribute maps.

  Each adapter MUST handle at minimum:
  - Native token transfers (from the transaction's `value` field when > 0)
  - ERC-20 `Transfer(address,address,uint256)` events

  Each returned map should include:
  - `:from_address` — sender
  - `:to_address` — recipient
  - `:token_contract_address` — contract address (or native token placeholder)
  - `:amount` — the raw transfer amount as a `Decimal`
  - `:token_type` — `:native`, `:erc20`, `:erc721`, or `:erc1155`
  - `:token_id` — nil for fungible tokens, token ID for NFTs
  """
  @callback extract_token_transfers(transaction :: map()) :: [map()]
end
