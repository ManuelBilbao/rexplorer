defmodule Rexplorer.Decoder.Narrator do
  @moduledoc """
  Composes semantic actions into human-readable summary strings.

  Resolves token addresses to symbols using the token registry and
  formats amounts with proper decimal conversion and thousand separators.
  """

  alias Rexplorer.Decoder.Action

  @doc """
  Narrates an action into a human-readable string.

  Uses `token_cache` (a map of `address => %{symbol, decimals}`) for token resolution.
  """
  def narrate(%Action{type: :swap, protocol: protocol, params: params}, token_cache) do
    token_in = resolve_token(params[:token_in], token_cache)
    token_out = resolve_token(params[:token_out], token_cache)
    amount_in = format_token_amount(params[:amount_in], token_in)
    amount_out = format_token_amount(params[:amount_out_min] || params[:amount_out], token_out)

    actor = truncate_address(params[:from])
    parts = [actor, "swapped"]
    parts = if amount_in, do: parts ++ [amount_in, token_in.symbol], else: parts
    parts = parts ++ ["for"]
    parts = if amount_out, do: parts ++ [amount_out, token_out.symbol], else: parts ++ [token_out.symbol]
    parts = parts ++ ["on", protocol]

    Enum.join(parts, " ")
  end

  def narrate(%Action{type: :transfer, params: params}, token_cache) do
    token = resolve_token(params[:token], token_cache)
    amount = format_token_amount(params[:amount], token)
    from = truncate_address(params[:from])
    to = truncate_address(params[:to])
    "#{from} transferred #{amount} #{token.symbol} to #{to}"
  end

  def narrate(%Action{type: :transfer_from, params: params}, token_cache) do
    token = resolve_token(params[:token], token_cache)
    amount = format_token_amount(params[:amount], token)
    from = truncate_address(params[:from])
    to = truncate_address(params[:to])
    "#{from} transferred #{amount} #{token.symbol} to #{to}"
  end

  def narrate(%Action{type: :approve, params: params}, token_cache) do
    token = resolve_token(params[:token], token_cache)
    actor = truncate_address(params[:from])
    spender = truncate_address(params[:spender])
    amount = format_token_amount(params[:amount], token)
    "#{actor} approved #{spender} to spend #{amount} #{token.symbol}"
  end

  def narrate(%Action{type: :wrap, params: params}, _token_cache) do
    actor = truncate_address(params[:from])
    amount = format_raw_amount(params[:amount], 18)
    "#{actor} wrapped #{amount} ETH to WETH"
  end

  def narrate(%Action{type: :unwrap, params: params}, _token_cache) do
    actor = truncate_address(params[:from])
    amount = format_raw_amount(params[:amount], 18)
    "#{actor} unwrapped #{amount} WETH to ETH"
  end

  def narrate(%Action{type: :supply, protocol: protocol, params: params}, token_cache) do
    token = resolve_token(params[:asset], token_cache)
    actor = truncate_address(params[:from])
    amount = format_token_amount(params[:amount], token)
    "#{actor} supplied #{amount} #{token.symbol} to #{protocol}"
  end

  def narrate(%Action{type: :withdraw, protocol: protocol, params: params}, token_cache) do
    token = resolve_token(params[:asset], token_cache)
    actor = truncate_address(params[:from])
    amount = format_token_amount(params[:amount], token)
    "#{actor} withdrew #{amount} #{token.symbol} from #{protocol}"
  end

  def narrate(%Action{type: :borrow, protocol: protocol, params: params}, token_cache) do
    token = resolve_token(params[:asset], token_cache)
    actor = truncate_address(params[:from])
    amount = format_token_amount(params[:amount], token)
    "#{actor} borrowed #{amount} #{token.symbol} from #{protocol}"
  end

  def narrate(%Action{type: :repay, protocol: protocol, params: params}, token_cache) do
    token = resolve_token(params[:asset], token_cache)
    amount = format_token_amount(params[:amount], token)
    "Repaid #{amount} #{token.symbol} to #{protocol}"
  end

  def narrate(%Action{type: type, protocol: protocol}, _token_cache) do
    "#{humanize(type)} on #{protocol}"
  end

  @doc "Generates a fallback narration for unknown calls."
  def fallback_narrate(decoded, to_address) do
    case decoded do
      %{function: function} when is_binary(function) ->
        "Called #{function} on #{truncate_address(to_address)}"

      _ ->
        "Called #{truncate_address(to_address)}"
    end
  end

  # Token resolution

  @doc """
  Builds a token cache from the database for a given chain.
  Returns a map of `lowercase_address => %{symbol: string, decimals: integer}`.
  """
  def build_token_cache(chain_id) do
    import Ecto.Query

    Rexplorer.Repo.all(
      from ta in Rexplorer.Schema.TokenAddress,
        join: t in assoc(ta, :token),
        where: ta.chain_id == ^chain_id,
        select: {ta.contract_address, %{symbol: t.symbol, decimals: t.decimals}}
    )
    |> Map.new(fn {addr, info} -> {String.downcase(addr), info} end)
  end

  defp resolve_token(nil, _cache), do: %{symbol: "???", decimals: nil}

  defp resolve_token(address, cache) when is_binary(address) do
    Map.get(cache, String.downcase(address), %{symbol: address, decimals: nil})
  end

  defp resolve_token(_, _), do: %{symbol: "???", decimals: nil}

  # Amount formatting

  # Max uint256 ≈ 1.15e77 — anything above 1e30 is effectively "unlimited"
  @unlimited_threshold round(:math.pow(10, 30))

  defp format_token_amount(nil, _token), do: "?"

  defp format_token_amount(amount, _token) when is_integer(amount) and amount >= @unlimited_threshold do
    "Unlimited"
  end

  defp format_token_amount(amount, %{decimals: nil}), do: to_string(amount)

  defp format_token_amount(amount, token) when is_integer(amount) do
    format_raw_amount(amount, token.decimals)
  end

  defp format_token_amount(amount, _token), do: to_string(amount)

  defp format_raw_amount(nil, _decimals), do: "?"

  defp format_raw_amount(amount, decimals) when is_integer(amount) and is_integer(decimals) do
    value = amount / :math.pow(10, decimals)

    if value == trunc(value) do
      trunc(value) |> format_number()
    else
      :erlang.float_to_binary(value, decimals: min(6, decimals))
      |> String.trim_trailing("0")
      |> String.trim_trailing(".")
    end
  end

  defp format_raw_amount(amount, _decimals), do: to_string(amount)

  defp format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp truncate_address(nil), do: "???"
  defp truncate_address(addr) when is_binary(addr), do: addr

  defp humanize(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
  end
end
