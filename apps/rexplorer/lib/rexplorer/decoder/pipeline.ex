defmodule Rexplorer.Decoder.Pipeline do
  @moduledoc """
  Orchestrates the decoder pipeline: ABI decode → interpret → narrate.

  This module contains pure logic (no side effects except token cache lookup).
  The `decode_operation/2` function is the main entry point, used by the
  decoder worker to process individual operations.
  """

  alias Rexplorer.Decoder.{ABI, Narrator}
  alias Rexplorer.Decoder.Interpreter.Registry, as: InterpreterRegistry

  @decoder_version 1

  @doc "Returns the current decoder version."
  def decoder_version, do: @decoder_version

  @doc """
  Decodes an operation and returns a human-readable summary.

  Takes an operation map with `:input`, `:to_address`, `:value`, `:chain_id`
  and a token cache (from `Narrator.build_token_cache/1`).

  Returns `{:ok, summary_string}` or `{:error, reason}`.
  """
  def decode_operation(operation, token_cache) do
    input = operation.input
    to_address = operation.to_address
    chain_id = operation.chain_id

    tx_context = %{
      from_address: operation.from_address,
      to_address: to_address,
      value: decimal_to_integer(operation.value)
    }

    case ABI.decode(input) do
      {:ok, decoded} ->
        case InterpreterRegistry.interpret(to_address, decoded, tx_context, chain_id) do
          {:ok, action} ->
            summary = Narrator.narrate(action, token_cache)
            {:ok, summary}

          {:error, :no_interpreter} ->
            summary = Narrator.fallback_narrate(decoded, to_address)
            {:ok, summary}
        end

      {:error, :unknown_selector} ->
        if to_address do
          selector_hex = if input && byte_size(input) >= 4 do
            "0x" <> Base.encode16(binary_part(input, 0, 4), case: :lower)
          else
            "unknown"
          end

          {:ok, "Called #{selector_hex} on #{truncate(to_address)}"}
        else
          {:ok, "Contract creation"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decimal_to_integer(%Decimal{} = d), do: Decimal.to_integer(d)
  defp decimal_to_integer(n) when is_integer(n), do: n
  defp decimal_to_integer(_), do: 0

  defp truncate(addr) when is_binary(addr) and byte_size(addr) > 12 do
    String.slice(addr, 0, 6) <> "..." <> String.slice(addr, -4, 4)
  end

  defp truncate(addr), do: addr || "???"
end
