defmodule RexplorerWeb.API.V1.BalanceHistoryController do
  @moduledoc """
  Public API endpoint for address balance history.

  Serves `GET /api/v1/chains/:chain_slug/addresses/:address_hash/balance-history`
  returning a time-ordered list of balance data points for charting.

  ## Query Parameters

  - `before` — block_number cursor for pagination
  - `limit` — max results (default 500, max 2000)
  """

  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Addresses"]

  operation :index,
    summary: "Get address balance history",
    description: "Returns historical native-token balance data points for charting.",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      address_hash: [in: :path, type: :string, required: true],
      before: [in: :query, type: :integer, description: "Block number cursor"],
      limit: [in: :query, type: :integer, description: "Max results (default 500, max 2000)"]
    ],
    responses: [
      ok: {"Balance history", "application/json", nil},
      not_found: {"Not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def index(conn, %{"address_hash" => hash} = params) do
    chain_id = conn.assigns.chain_id

    opts =
      []
      |> maybe_put(:before, params["before"] && String.to_integer(params["before"]))
      |> maybe_put(:limit, params["limit"] && String.to_integer(params["limit"]))

    case Rexplorer.Balances.get_balance_history(chain_id, hash, opts) do
      {:ok, entries, next_cursor} ->
        json(conn, %{
          data:
            Enum.map(entries, fn e ->
              %{
                block_number: e.block_number,
                balance_wei: to_string(e.balance_wei),
                timestamp: e.timestamp
              }
            end),
          next_cursor: next_cursor
        })
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
