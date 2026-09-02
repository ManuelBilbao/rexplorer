defmodule RexplorerWeb.API.V1.OperationController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Operation, Schema.Transaction}

  tags ["Operations"]

  operation :index,
    summary: "List operations for a transaction",
    description: "Returns the user-intent operations extracted from a transaction (e.g., individual calls within a multicall, UserOperations within an AA bundle).",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      transaction_hash: [in: :path, type: :string, description: "Parent transaction hash", required: true]
    ],
    responses: [
      ok: {"Operation list", "application/json", RexplorerWeb.Schemas.OperationListResponse},
      not_found: {"Transaction not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def index(conn, %{"transaction_hash" => tx_hash}) do
    chain_id = conn.assigns.chain_id
    tx_hash = String.downcase(tx_hash)

    case Repo.get_by(Transaction, chain_id: chain_id, hash: tx_hash) do
      nil ->
        {:error, :not_found}

      tx ->
        operations =
          Operation
          |> where([o], o.transaction_id == ^tx.id)
          |> order_by([o], o.operation_index)
          |> Repo.all()

        json(conn, %{data: Enum.map(operations, &operation_json/1)})
    end
  end

  defp operation_json(op) do
    %{
      operation_type: op.operation_type,
      operation_index: op.operation_index,
      from_address: op.from_address,
      to_address: op.to_address,
      value: to_string(op.value),
      decoded_summary: op.decoded_summary
    }
  end
end
