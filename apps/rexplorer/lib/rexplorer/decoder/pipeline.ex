defmodule Rexplorer.Decoder.Pipeline do
  @moduledoc """
  Orchestrates the decoder pipeline: ABI decode → interpret → narrate.

  This module contains pure logic (no side effects except token cache lookup).
  The `decode_operation/2` function is the main entry point, used by the
  decoder worker to process individual operations.
  """

  alias Rexplorer.Decoder.{ABI, Narrator}
  alias Rexplorer.Decoder.Interpreter.Registry, as: InterpreterRegistry

  @decoder_version 2

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
    operation_type = get_operation_type(operation)

    tx_context = %{
      from_address: operation.from_address,
      to_address: to_address,
      value: decimal_to_integer(operation.value)
    }

    inner_summary = decode_inner(input, to_address, tx_context, chain_id, token_cache)

    case inner_summary do
      {:ok, summary} -> {:ok, wrap_with_context(summary, operation_type, operation.from_address)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_inner(input, to_address, tx_context, chain_id, token_cache) do
    case ABI.decode(input) do
      {:ok, decoded} ->
        case InterpreterRegistry.interpret(to_address, decoded, tx_context, chain_id) do
          {:ok, action} -> {:ok, Narrator.narrate(action, token_cache)}
          {:error, :no_interpreter} -> {:ok, Narrator.fallback_narrate(decoded, to_address)}
        end

      {:error, :unknown_selector} ->
        cond do
          is_nil(to_address) ->
            {:ok, "Contract creation"}

          is_nil(input) or input == <<>> or input == "" ->
            # Plain value transfer (no calldata)
            amount = tx_context.value
            symbol = native_token_symbol(chain_id)
            {:ok, "#{tx_context.from_address} transferred #{Narrator.format_native_amount(amount)} #{symbol} to #{to_address}"}

          true ->
            selector_hex =
              if byte_size(input) >= 4 do
                "0x" <> Base.encode16(binary_part(input, 0, 4), case: :lower)
              else
                "unknown"
              end

            {:ok, "Called #{selector_hex} on #{to_address}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp wrap_with_context(summary, :multisig_execution, from_address) do
    "Safe #{from_address}: #{summary}"
  end

  defp wrap_with_context(summary, :delegate_call, from_address) do
    "Safe #{from_address} (delegatecall): #{summary}"
  end

  defp wrap_with_context(summary, :multicall_item, _from_address) do
    summary
  end

  defp wrap_with_context(summary, _type, _from_address) do
    summary
  end

  defp get_operation_type(%{operation_type: type}) when is_atom(type), do: type
  defp get_operation_type(%{operation_type: type}) when is_binary(type), do: String.to_existing_atom(type)
  defp get_operation_type(_), do: :call

  defp decimal_to_integer(%Decimal{} = d), do: Decimal.to_integer(d)
  defp decimal_to_integer(n) when is_integer(n), do: n
  defp decimal_to_integer(_), do: 0

  defp native_token_symbol(chain_id) do
    case Rexplorer.Chain.Registry.get_adapter(chain_id) do
      {:ok, adapter} -> adapter.native_token() |> elem(0)
      _ -> "ETH"
    end
  end


end
