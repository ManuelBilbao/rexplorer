defmodule Rexplorer.Decoder.Interpreter.UniswapV2 do
  @moduledoc "Interprets Uniswap V2 Router swap calls."

  @behaviour Rexplorer.Decoder.Interpreter
  alias Rexplorer.Decoder.Action

  @router_addresses %{
    1 => ["0x7a250d5630b4cf539739df2c5dacb4c659f2488d"],
    10 => ["0x4a7b5da61326a6379179b2a7b5ae993c4e7c3129"],
    8453 => ["0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"],
    56 => ["0x10ed43c718714eb63d5aa57b78b54704e256024e"],
    137 => ["0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff"]
  }

  @swap_functions [
    "swapExactTokensForTokens",
    "swapTokensForExactTokens",
    "swapExactETHForTokens",
    "swapETHForExactTokens"
  ]

  @impl true
  def matches?(to_address, %{function: function}, chain_id) do
    addresses = Map.get(@router_addresses, chain_id, [])
    to_address in addresses and function in @swap_functions
  end

  def matches?(_, _, _), do: false

  @impl true
  def interpret(%{function: function, params: params}, tx_context, _chain_id) do
    path = params["path"] || params["param2"] || []

    {amount_in, amount_out_min} =
      case function do
        "swapExactTokensForTokens" ->
          {params["amountIn"] || params["param0"], params["amountOutMin"] || params["param1"]}

        "swapTokensForExactTokens" ->
          {params["amountInMax"] || params["param1"], params["amountOut"] || params["param0"]}

        "swapExactETHForTokens" ->
          {tx_context.value, params["amountOutMin"] || params["param0"]}

        "swapETHForExactTokens" ->
          {tx_context.value, params["amountOut"] || params["param0"]}

        _ ->
          {nil, nil}
      end

    token_in = List.first(path)
    token_out = List.last(path)

    {:ok,
     %Action{
       type: :swap,
       protocol: "Uniswap V2",
       params: %{
         from: tx_context.from_address,
         token_in: format_address(token_in),
         token_out: format_address(token_out),
         amount_in: amount_in,
         amount_out_min: amount_out_min
       }
     }}
  end

  def interpret(_, _, _), do: {:error, :unhandled_function}

  defp format_address(addr) when is_binary(addr), do: String.downcase(addr)
  defp format_address(addr) when is_integer(addr), do: "0x" <> Integer.to_string(addr, 16) |> String.downcase() |> String.pad_leading(42, "0")
  defp format_address(nil), do: nil
end
