defmodule Rexplorer.Decoder.Interpreter.WETH do
  @moduledoc "Interprets WETH deposit (wrap) and withdraw (unwrap) calls."

  @behaviour Rexplorer.Decoder.Interpreter
  alias Rexplorer.Decoder.Action

  @weth_addresses %{
    1 => ["0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"],
    10 => ["0x4200000000000000000000000000000000000006"],
    8453 => ["0x4200000000000000000000000000000000000006"],
    56 => ["0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"],
    137 => ["0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270"]
  }

  @impl true
  def matches?(to_address, %{function: function}, chain_id) do
    addresses = Map.get(@weth_addresses, chain_id, [])
    to_address in addresses and function in ["deposit", "withdraw"]
  end

  def matches?(_, _, _), do: false

  @impl true
  def interpret(%{function: "deposit"}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :wrap,
       protocol: "WETH",
       params: %{from: tx_context.from_address, amount: tx_context.value}
     }}
  end

  def interpret(%{function: "withdraw", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :unwrap,
       protocol: "WETH",
       params: %{from: tx_context.from_address, amount: params["wad"] || params["amount"] || params["param0"]}
     }}
  end

  def interpret(_, _, _), do: {:error, :unhandled_function}
end
