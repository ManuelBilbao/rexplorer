defmodule Rexplorer.Decoder.Interpreter.ERC20 do
  @moduledoc "Interprets ERC-20 transfer, transferFrom, and approve calls."

  @behaviour Rexplorer.Decoder.Interpreter
  alias Rexplorer.Decoder.Action

  @functions ["transfer", "transferFrom", "approve"]

  @impl true
  def matches?(_to_address, %{function: function}, _chain_id) do
    function in @functions
  end

  def matches?(_, _, _), do: false

  @impl true
  def interpret(%{function: "transfer", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :transfer,
       protocol: "ERC-20",
       params: %{
         token: tx_context.to_address,
         from: tx_context.from_address,
         to: params["to"] || params["param0"],
         amount: params["amount"] || params["value"] || params["param1"]
       }
     }}
  end

  def interpret(%{function: "transferFrom", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :transfer_from,
       protocol: "ERC-20",
       params: %{
         token: tx_context.to_address,
         from: params["from"] || params["param0"],
         to: params["to"] || params["param1"],
         amount: params["amount"] || params["value"] || params["param2"]
       }
     }}
  end

  def interpret(%{function: "approve", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :approve,
       protocol: "ERC-20",
       params: %{
         token: tx_context.to_address,
         spender: params["spender"] || params["param0"],
         amount: params["amount"] || params["value"] || params["param1"]
       }
     }}
  end

  def interpret(_, _, _), do: {:error, :unhandled_function}
end
