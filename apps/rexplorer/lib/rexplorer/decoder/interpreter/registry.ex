defmodule Rexplorer.Decoder.Interpreter.Registry do
  @moduledoc """
  Routes decoded calls to the correct protocol interpreter.

  Iterates through registered interpreters in order and returns the first match.
  More specific interpreters (Uniswap, Aave) come before generic ones (ERC-20).
  """

  alias Rexplorer.Decoder.Interpreter

  @interpreters [
    Interpreter.UniswapV3,
    Interpreter.UniswapV2,
    Interpreter.WETH,
    Interpreter.AaveV3,
    Interpreter.ERC20
  ]

  @doc """
  Finds the matching interpreter and returns its action.

  Returns `{:ok, %Action{}}` or `{:error, :no_interpreter}`.
  """
  def interpret(to_address, decoded, tx_context, chain_id) do
    @interpreters
    |> Enum.find(fn mod -> mod.matches?(to_address, decoded, chain_id) end)
    |> case do
      nil -> {:error, :no_interpreter}
      mod -> mod.interpret(decoded, tx_context, chain_id)
    end
  end
end
