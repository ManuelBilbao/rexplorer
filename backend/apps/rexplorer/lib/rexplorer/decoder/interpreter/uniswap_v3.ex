defmodule Rexplorer.Decoder.Interpreter.UniswapV3 do
  @moduledoc "Interprets Uniswap V3 SwapRouter calls."

  @behaviour Rexplorer.Decoder.Interpreter
  alias Rexplorer.Decoder.Action

  @router_addresses %{
    1 => ["0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45", "0xe592427a0aece92de3edee1f18e0157c05861564"],
    10 => ["0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45"],
    8453 => ["0x2626664c2603336e57b271c5c0b26f421741e481"],
    56 => ["0xb971ef87ede563556b2ed4b1c0b0019111dd85d2"],
    137 => ["0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45"]
  }

  @swap_functions ["exactInputSingle", "exactInput", "exactOutputSingle", "exactOutput"]

  @impl true
  def matches?(to_address, %{function: function}, chain_id) do
    addresses = Map.get(@router_addresses, chain_id, [])
    to_address in addresses and function in @swap_functions
  end

  def matches?(_, _, _), do: false

  @impl true
  def interpret(%{function: "exactInputSingle", params: params}, tx_context, _chain_id) do
    # params is a tuple struct: (tokenIn, tokenOut, fee, recipient, amountIn, amountOutMinimum, sqrtPriceLimitX96)
    p = extract_single_params(params)

    {:ok,
     %Action{
       type: :swap,
       protocol: "Uniswap V3",
       params: %{
         from: tx_context.from_address,
         token_in: p.token_in,
         token_out: p.token_out,
         amount_in: p.amount_in
       }
     }}
  end

  def interpret(%{function: "exactOutputSingle", params: params}, tx_context, _chain_id) do
    p = extract_single_params(params)

    {:ok,
     %Action{
       type: :swap,
       protocol: "Uniswap V3",
       params: %{
         from: tx_context.from_address,
         token_in: p.token_in,
         token_out: p.token_out,
         amount_out: p.amount_out
       }
     }}
  end

  def interpret(%{function: "exactInput", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :swap,
       protocol: "Uniswap V3",
       params: %{
         from: tx_context.from_address,
         amount_in: params["amountIn"] || params["param2"]
       }
     }}
  end

  def interpret(%{function: "exactOutput", params: params}, tx_context, _chain_id) do
    {:ok,
     %Action{
       type: :swap,
       protocol: "Uniswap V3",
       params: %{
         from: tx_context.from_address,
         amount_out: params["amountOut"] || params["param2"]
       }
     }}
  end

  def interpret(_, _, _), do: {:error, :unhandled_function}

  defp extract_single_params(params) do
    # ex_abi decodes tuple params as a nested tuple or map
    # Handle both formats
    cond do
      is_map(params["params"]) ->
        p = params["params"]
        %{
          token_in: format_addr(p["tokenIn"] || p["param0"]),
          token_out: format_addr(p["tokenOut"] || p["param1"]),
          amount_in: p["amountIn"] || p["param4"],
          amount_out: p["amountOutMinimum"] || p["param5"]
        }

      true ->
        p0 = params["param0"]
        if is_tuple(p0) do
          list = Tuple.to_list(p0)
          %{
            token_in: format_addr(Enum.at(list, 0)),
            token_out: format_addr(Enum.at(list, 1)),
            amount_in: Enum.at(list, 4),
            amount_out: Enum.at(list, 5)
          }
        else
          %{token_in: nil, token_out: nil, amount_in: nil, amount_out: nil}
        end
    end
  end

  defp format_addr(addr) when is_binary(addr), do: String.downcase(addr)
  defp format_addr(addr) when is_integer(addr) do
    hex = Integer.to_string(addr, 16) |> String.downcase()
    "0x" <> String.pad_leading(hex, 40, "0")
  end
  defp format_addr(nil), do: nil
end
