defmodule Rexplorer.Unwrapper.Registry do
  @moduledoc """
  Routes transactions to the correct unwrapper.

  Iterates registered unwrappers and returns operations from the first match.
  Falls back to a single `:call` operation if no unwrapper matches.
  """

  @unwrappers [
    Rexplorer.Unwrapper.Safe,
    Rexplorer.Unwrapper.Multicall
  ]

  @doc """
  Unwraps a transaction into operations.

  Returns a list of operation attribute maps. If no unwrapper matches,
  returns a single `:call` operation (preserving current behavior).
  """
  def unwrap(transaction, chain_id) do
    case Enum.find(@unwrappers, fn mod -> mod.matches?(transaction, chain_id) end) do
      nil -> default_operation(transaction)
      mod ->
        case mod.unwrap(transaction, chain_id) do
          [] -> default_operation(transaction)
          ops -> ops
        end
    end
  rescue
    _ -> default_operation(transaction)
  end

  defp default_operation(transaction) do
    [
      %{
        operation_type: :call,
        operation_index: 0,
        from_address: transaction.from_address,
        to_address: transaction.to_address,
        value: transaction.value,
        input: transaction.input
      }
    ]
  end
end
