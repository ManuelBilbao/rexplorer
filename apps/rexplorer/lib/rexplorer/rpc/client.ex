defmodule Rexplorer.RPC.Client do
  @moduledoc """
  Stateless JSON-RPC client for Ethereum-compatible blockchain nodes.

  Provides a thin wrapper over HTTP for standard Ethereum JSON-RPC methods.
  All functions take an RPC URL as the first argument and return `{:ok, result}`
  or `{:error, reason}`.

  ## Supported Methods

  - `get_latest_block_number/1` — `eth_blockNumber`
  - `get_block/2` — `eth_getBlockByNumber` (with full transaction objects)
  - `get_block_receipts/2` — `eth_getBlockReceipts`
  - `call/3` — arbitrary JSON-RPC method call

  ## Example

      {:ok, block_number} = Rexplorer.RPC.Client.get_latest_block_number("http://localhost:8545")
      {:ok, block} = Rexplorer.RPC.Client.get_block("http://localhost:8545", block_number)
  """

  @doc """
  Makes a single JSON-RPC call to the given URL.

  Returns `{:ok, result}` on success, `{:error, %{code: integer, message: string}}`
  for JSON-RPC errors, or `{:error, reason}` for network failures.
  """
  def call(url, method, params \\ []) do
    body = %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => method,
      "params" => params
    }

    case Req.post(url, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"result" => result}}} ->
        {:ok, result}

      {:ok, %Req.Response{status: 200, body: %{"error" => error}}} ->
        {:error, %{code: error["code"], message: error["message"]}}

      {:ok, %Req.Response{status: status}} ->
        {:error, %{http_status: status}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Returns the latest block number as an integer.
  """
  def get_latest_block_number(url) do
    case call(url, "eth_blockNumber") do
      {:ok, hex} -> {:ok, hex_to_integer(hex)}
      error -> error
    end
  end

  @doc """
  Fetches a block by number with full transaction objects.

  Returns `{:ok, block_map}` or `{:ok, nil}` if the block doesn't exist yet.
  """
  def get_block(url, block_number) do
    call(url, "eth_getBlockByNumber", [integer_to_hex(block_number), true])
  end

  @doc """
  Fetches all transaction receipts for a block in a single call.

  Uses the `eth_getBlockReceipts` method. Returns `{:ok, [receipt, ...]}`.
  """
  def get_block_receipts(url, block_number) do
    call(url, "eth_getBlockReceipts", [integer_to_hex(block_number)])
  end

  # Ethrex-specific RPC methods

  @doc "Returns batch info for a given block number on an Ethrex chain."
  def ethrex_get_batch_by_block(url, block_number) do
    call(url, "ethrex_getBatchByBlock", [integer_to_hex(block_number)])
  end

  @doc "Returns batch details by batch number on an Ethrex chain."
  def ethrex_get_batch_by_number(url, batch_number) do
    call(url, "ethrex_getBatchByNumber", [integer_to_hex(batch_number), false])
  end

  @doc "Returns the latest batch number on an Ethrex chain."
  def ethrex_batch_number(url) do
    case call(url, "ethrex_batchNumber") do
      {:ok, hex} -> {:ok, hex_to_integer(hex)}
      error -> error
    end
  end

  # Hex encoding/decoding helpers

  @doc "Converts a hex string (with 0x prefix) to an integer."
  def hex_to_integer("0x" <> hex), do: String.to_integer(hex, 16)
  def hex_to_integer(nil), do: nil

  @doc "Converts an integer to a hex string with 0x prefix."
  def integer_to_hex(n) when is_integer(n), do: "0x" <> Integer.to_string(n, 16)

  @doc "Converts a hex string (with 0x prefix) to a binary."
  def hex_to_binary("0x" <> hex), do: Base.decode16!(hex, case: :mixed)
  def hex_to_binary(nil), do: nil
  def hex_to_binary(""), do: <<>>
end
