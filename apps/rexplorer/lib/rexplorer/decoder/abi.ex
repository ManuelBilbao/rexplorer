defmodule Rexplorer.Decoder.ABI do
  @moduledoc """
  ABI registry for decoding EVM calldata.

  Maintains an ETS table (`:rexplorer_abi_registry`) mapping 4-byte function
  selectors to their ABI definitions. Preloaded with common function signatures
  for ERC-20, Uniswap V2/V3, WETH, and Aave V3.

  Uses `ex_abi` for ABI parsing/decoding and `ex_keccak` for Keccak-256 hashing
  to compute selectors.
  """

  use GenServer

  @ets_table :rexplorer_abi_registry

  # Known function signatures grouped by protocol
  @known_signatures [
    # ERC-20
    "transfer(address,uint256)",
    "transferFrom(address,address,uint256)",
    "approve(address,uint256)",

    # Uniswap V2
    "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
    "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)",
    "swapExactETHForTokens(uint256,address[],address,uint256)",
    "swapETHForExactTokens(uint256,address[],address,uint256)",

    # Uniswap V3
    "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
    "exactInput((bytes,address,uint256,uint256))",
    "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))",
    "exactOutput((bytes,address,uint256,uint256))",

    # WETH
    "deposit()",
    "withdraw(uint256)",

    # Aave V3
    "supply(address,uint256,address,uint16)",
    "withdraw(address,uint256,address)",
    "borrow(address,uint256,uint256,uint16,address)",
    "repay(address,uint256,uint256,address)"
  ]

  # Human-readable parameter names for signatures whose ABI.FunctionSelector
  # does not include input_names (i.e. they come back as []).
  @param_names %{
    "transfer" => ["to", "value"],
    "transferFrom" => ["from", "to", "value"],
    "approve" => ["spender", "value"],
    "swapExactTokensForTokens" => ["amountIn", "amountOutMin", "path", "to", "deadline"],
    "swapTokensForExactTokens" => ["amountOut", "amountInMax", "path", "to", "deadline"],
    "swapExactETHForTokens" => ["amountOutMin", "path", "to", "deadline"],
    "swapETHForExactTokens" => ["amountOut", "path", "to", "deadline"],
    "exactInputSingle" => ["params"],
    "exactInput" => ["params"],
    "exactOutputSingle" => ["params"],
    "exactOutput" => ["params"],
    "deposit" => [],
    "withdraw" => ["amount"],
    "supply" => ["asset", "amount", "onBehalfOf", "referralCode"],
    "borrow" => ["asset", "amount", "interestRateMode", "referralCode", "onBehalfOf"],
    "repay" => ["asset", "amount", "interestRateMode", "onBehalfOf"]
  }

  # -------------------------------------------------------------------
  # Public API
  # -------------------------------------------------------------------

  @doc """
  Starts the ABI registry GenServer, creating the ETS table and populating it
  with known function selectors.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Looks up a 4-byte binary selector in the registry.

  Returns the stored ABI entry map or `nil` if the selector is not registered.

  ## Examples

      iex> Rexplorer.Decoder.ABI.lookup_selector(<<0xA9, 0x05, 0x9C, 0xBB>>)
      %{function: "transfer", selector: %ABI.FunctionSelector{...}, param_names: ["to", "value"]}

      iex> Rexplorer.Decoder.ABI.lookup_selector(<<0, 0, 0, 0>>)
      nil
  """
  @spec lookup_selector(<<_::32>>) :: map() | nil
  def lookup_selector(<<_::binary-size(4)>> = selector) do
    case :ets.lookup(@ets_table, selector) do
      [{^selector, entry}] -> entry
      [] -> nil
    end
  end

  @doc """
  Decodes raw calldata binary into a structured map.

  Extracts the first 4 bytes as the function selector, looks it up in the
  registry, and decodes the remaining bytes as ABI-encoded parameters.

  Returns `{:ok, %{function: name, params: %{param_name => value}}}` on success,
  or `{:error, :unknown_selector}` if the selector is not in the registry.

  ## Examples

      iex> calldata = <<...>>  # valid transfer calldata
      iex> Rexplorer.Decoder.ABI.decode(calldata)
      {:ok, %{function: "transfer", params: %{"to" => <<...>>, "value" => 1000}}}
  """
  @spec decode(binary()) :: {:ok, map()} | {:error, :unknown_selector}
  def decode(<<selector::binary-size(4), params_data::binary>>) do
    case lookup_selector(selector) do
      nil ->
        {:error, :unknown_selector}

      %{function: name, selector: function_selector, param_names: param_names} ->
        decoded_values = ABI.decode(function_selector, params_data)

        names =
          if param_names == [] do
            Enum.with_index(decoded_values, fn _v, i -> "param#{i}" end)
          else
            param_names
          end

        types = function_selector.types

        params =
          names
          |> Enum.zip(decoded_values)
          |> Enum.zip(types ++ List.duplicate(nil, max(0, length(names) - length(types))))
          |> Enum.map(fn {{name, value}, type} -> {name, format_value(value, type)} end)
          |> Map.new()

        {:ok, %{function: name, params: params}}
    end
  end

  def decode(_calldata), do: {:error, :unknown_selector}

  # -------------------------------------------------------------------
  # GenServer callbacks
  # -------------------------------------------------------------------

  @impl true
  def init([]) do
    table = :ets.new(@ets_table, [:named_table, :set, :public, read_concurrency: true])

    Enum.each(@known_signatures, &register_signature/1)

    {:ok, %{table: table}}
  end

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp register_signature(signature) do
    fs = ABI.FunctionSelector.decode(signature)
    sig_string = ABI.FunctionSelector.encode(fs)
    hash = ExKeccak.hash_256(sig_string)
    selector = binary_part(hash, 0, 4)

    name = fs.function

    param_names =
      if fs.input_names != [] do
        fs.input_names
      else
        Map.get(@param_names, name, [])
      end

    entry = %{
      function: name,
      selector: fs,
      param_names: param_names
    }

    :ets.insert(@ets_table, {selector, entry})
  end

  # Convert decoded ABI values to friendly formats
  defp format_value(value, :address) when is_binary(value) and byte_size(value) == 20 do
    "0x" <> Base.encode16(value, case: :lower)
  end

  defp format_value(values, {:array, :address}) when is_list(values) do
    Enum.map(values, &format_value(&1, :address))
  end

  defp format_value(value, {:tuple, _}) when is_tuple(value) do
    # Tuples from struct params (e.g., Uniswap V3 ExactInputSingleParams)
    # Return as-is for now; interpreters handle tuple extraction
    value
  end

  defp format_value(value, _type), do: value
end
