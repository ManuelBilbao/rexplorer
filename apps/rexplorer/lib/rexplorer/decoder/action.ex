defmodule Rexplorer.Decoder.Action do
  @moduledoc """
  Represents a semantic interpretation of a decoded call.

  An action is the output of a protocol interpreter — it describes
  what a call *means* rather than what function was called.

  ## Fields

  - `:type` — the action type atom (`:swap`, `:transfer`, `:approve`, `:wrap`, `:unwrap`, `:supply`, `:withdraw`, `:borrow`, `:repay`)
  - `:protocol` — human-readable protocol name ("Uniswap V3", "Aave V3", "ERC-20")
  - `:params` — action-specific parameters (token addresses, amounts, etc.)
  """

  defstruct [:type, :protocol, :params]

  @type t :: %__MODULE__{
          type: atom(),
          protocol: String.t(),
          params: map()
        }
end
