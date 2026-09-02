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

  ## Example

      {:ok, "0x1"} = Client.call("http://localhost:8545", "eth_blockNumber")
  """
  def call(url, method, params \\ [], opts \\ []) do
    body = %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => method,
      "params" => params
    }

    timeout = opts[:timeout] || 30_000

    case Req.post(url, json: body, receive_timeout: timeout) do
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

  @doc """
  Makes a batch JSON-RPC call (sends an array of requests, receives an array of responses).

  Takes a list of `{method, params}` tuples. Returns `{:ok, results}` where results
  is a list of `{:ok, result}` or `{:error, reason}` in the same order as the input.

  ## Example

      {:ok, results} = Client.batch_call(url, [
        {"eth_getBalance", ["0xabc...", "0x1F4"]},
        {"eth_getBalance", ["0xdef...", "0x1F4"]}
      ])
  """
  def batch_call(url, calls, opts \\ []) when is_list(calls) do
    if calls == [], do: {:ok, []}

    body =
      calls
      |> Enum.with_index(1)
      |> Enum.map(fn {{method, params}, id} ->
        %{"jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params}
      end)

    timeout = opts[:timeout] || 60_000

    case Req.post(url, json: body, receive_timeout: timeout) do
      {:ok, %Req.Response{status: 200, body: responses}} when is_list(responses) ->
        # Sort by id to match input order
        sorted = Enum.sort_by(responses, & &1["id"])

        results =
          Enum.map(sorted, fn
            %{"result" => result} -> {:ok, result}
            %{"error" => error} -> {:error, %{code: error["code"], message: error["message"]}}
          end)

        {:ok, results}

      {:ok, %Req.Response{status: status}} ->
        {:error, %{http_status: status}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  # Balance and trace methods

  @doc """
  Returns the native token balance (in wei) for an address at a given block number.

  Calls `eth_getBalance(address, blockNumber)`. The block number is hex-encoded
  per the JSON-RPC spec.

  ## Example

      {:ok, 1_000_000_000_000_000_000} = Client.get_balance(url, "0xabc...", 100)
  """
  def get_balance(url, address, block_number) do
    case call(url, "eth_getBalance", [address, integer_to_hex(block_number)]) do
      {:ok, hex} -> {:ok, hex_to_integer(hex)}
      error -> error
    end
  end

  @doc """
  Fetches balances for multiple addresses at a given block in a single batch RPC call.

  Returns a map of `%{address => {:ok, balance_int} | {:error, reason}}`.
  Addresses are lowercased in the returned map. Requests are chunked into
  batches of `chunk_size` (default 500) to avoid overwhelming the node.

  ## Example

      results = Client.get_balances(url, ["0xabc...", "0xdef..."], 100)
      # %{"0xabc..." => {:ok, 1000000000000000000}, "0xdef..." => {:ok, 0}}
  """
  def get_balances(url, addresses, block_number, chunk_size \\ 500) do
    block_hex = integer_to_hex(block_number)

    addresses
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce(%{}, fn chunk, acc ->
      calls = Enum.map(chunk, fn addr -> {"eth_getBalance", [addr, block_hex]} end)

      case batch_call(url, calls) do
        {:ok, results} ->
          chunk
          |> Enum.zip(results)
          |> Enum.reduce(acc, fn {addr, result}, inner_acc ->
            parsed =
              case result do
                {:ok, hex} -> {:ok, hex_to_integer(hex)}
                error -> error
              end

            Map.put(inner_acc, String.downcase(addr), parsed)
          end)

        {:error, reason} ->
          # If the whole batch fails, mark all addresses as failed
          Enum.reduce(chunk, acc, fn addr, inner_acc ->
            Map.put(inner_acc, String.downcase(addr), {:error, reason})
          end)
      end
    end)
  end

  @doc """
  Traces all transactions in a block using the `callTracer` tracer.

  Calls `debug_traceBlockByNumber(blockNumber, {"tracer": "callTracer"})`.
  Returns a list of `%{"txHash" => ..., "result" => call_frame}` maps where
  each call frame contains nested `"calls"` with `from`, `to`, `value`, and `type`.

  ## Example

      {:ok, traces} = Client.trace_block(url, 100)
      # traces = [%{"txHash" => "0x...", "result" => %{"type" => "CALL", ...}}, ...]
  """
  def trace_block(url, block_number) do
    call(url, "debug_traceBlockByNumber", [
      block_number,
      %{"tracer" => "callTracer"}
    ])
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
