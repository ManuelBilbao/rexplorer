defmodule Rexplorer.Decoder.Interpreter do
  @moduledoc """
  Behaviour for protocol interpreters.

  Each interpreter knows about a specific protocol (Uniswap, Aave, ERC-20, etc.)
  and can determine if a decoded call belongs to it, then extract semantic meaning.
  """

  alias Rexplorer.Decoder.Action

  @doc """
  Returns true if this interpreter handles the given call.

  - `to_address` — the target contract address (lowercased hex)
  - `decoded` — `%{function: name, params: map}` from ABI decoding
  - `chain_id` — the EIP-155 chain ID
  """
  @callback matches?(to_address :: String.t(), decoded :: map(), chain_id :: integer()) :: boolean()

  @doc """
  Interprets the decoded call into a semantic action.

  - `decoded` — `%{function: name, params: map}` from ABI decoding
  - `tx_context` — transaction context (from_address, to_address, value, chain_id)
  - `chain_id` — the EIP-155 chain ID

  Returns `{:ok, %Action{}}` or `{:error, reason}`.
  """
  @callback interpret(decoded :: map(), tx_context :: map(), chain_id :: integer()) ::
              {:ok, Action.t()} | {:error, atom()}
end
