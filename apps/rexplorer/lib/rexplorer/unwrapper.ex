defmodule Rexplorer.Unwrapper do
  @moduledoc """
  Behaviour for transaction unwrappers.

  An unwrapper detects wrapper contract patterns (Safe multisig, Multicall, etc.)
  and decomposes the transaction into its inner operations.
  """

  @doc """
  Returns true if this unwrapper handles the given transaction.

  The transaction map contains at minimum: `:to_address`, `:from_address`,
  `:value`, `:input` (raw calldata binary).
  """
  @callback matches?(transaction :: map(), chain_id :: integer()) :: boolean()

  @doc """
  Unwraps the transaction into a list of operation attribute maps.

  Each operation map should include: `:operation_type`, `:operation_index`,
  `:from_address`, `:to_address`, `:value`, `:input`.
  """
  @callback unwrap(transaction :: map(), chain_id :: integer()) :: [map()]
end
