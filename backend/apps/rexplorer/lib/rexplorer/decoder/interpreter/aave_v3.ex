defmodule Rexplorer.Decoder.Interpreter.AaveV3 do
  @moduledoc "Interprets Aave V3 Pool supply, withdraw, borrow, and repay calls."

  @behaviour Rexplorer.Decoder.Interpreter
  alias Rexplorer.Decoder.Action

  @pool_addresses %{
    1 => ["0x87870bca3f3fd6335c3f4ce8392d69350b4fa4e2"],
    10 => ["0x794a61358d6845594f94dc1db02a252b5b4814ad"],
    8453 => ["0xa238dd80c259a72e81d7e4664a9801593f98d1c5"],
    137 => ["0x794a61358d6845594f94dc1db02a252b5b4814ad"]
  }

  @functions ["supply", "withdraw", "borrow", "repay"]

  @impl true
  def matches?(to_address, %{function: function}, chain_id) do
    addresses = Map.get(@pool_addresses, chain_id, [])
    to_address in addresses and function in @functions
  end

  def matches?(_, _, _), do: false

  @impl true
  def interpret(%{function: "supply", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :supply,
       protocol: "Aave V3",
       params: %{
         from: tx_context.from_address,
         asset: format_addr(params["asset"] || params["param0"]),
         amount: params["amount"] || params["param1"],
         on_behalf_of: format_addr(params["onBehalfOf"] || params["param2"])
       }
     }}
  end

  def interpret(%{function: "withdraw", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :withdraw,
       protocol: "Aave V3",
       params: %{
         from: tx_context.from_address,
         asset: format_addr(params["asset"] || params["param0"]),
         amount: params["amount"] || params["param1"]
       }
     }}
  end

  def interpret(%{function: "borrow", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :borrow,
       protocol: "Aave V3",
       params: %{
         from: tx_context.from_address,
         asset: format_addr(params["asset"] || params["param0"]),
         amount: params["amount"] || params["param1"]
       }
     }}
  end

  def interpret(%{function: "repay", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :repay,
       protocol: "Aave V3",
       params: %{
         from: tx_context.from_address,
         asset: format_addr(params["asset"] || params["param0"]),
         amount: params["amount"] || params["param1"]
       }
     }}
  end

  def interpret(_, _, _), do: {:error, :unhandled_function}

  defp format_addr(addr) when is_binary(addr), do: String.downcase(addr)
  defp format_addr(addr) when is_integer(addr) do
    hex = Integer.to_string(addr, 16) |> String.downcase()
    "0x" <> String.pad_leading(hex, 40, "0")
  end
  defp format_addr(nil), do: nil
end
