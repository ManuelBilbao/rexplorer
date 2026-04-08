defmodule RexplorerWeb.API.V1.InternalTransactionController do
  @moduledoc """
  Public API endpoint for address internal transactions.

  Serves `GET /api/v1/chains/:chain_slug/addresses/:address_hash/internal-transactions`
  returning paginated internal transactions (value-transferring trace entries).

  ## Query Parameters

  - `before` — block_number cursor for pagination
  - `limit` — max results (default 25, max 100)
  """

  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Internal Transactions"]

  operation :index,
    summary: "List internal transactions for an address",
    description: "Returns paginated internal transactions (value-transferring trace entries) involving the address.",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      address_hash: [in: :path, type: :string, required: true],
      before: [in: :query, type: :integer, description: "Block number cursor"],
      limit: [in: :query, type: :integer, description: "Max results (default 25, max 100)"]
    ],
    responses: [
      ok: {"Internal transaction list", "application/json", nil}
    ]

  def index(conn, %{"address_hash" => hash} = params) do
    chain_id = conn.assigns.chain_id

    opts =
      []
      |> maybe_put(:before, params["before"] && String.to_integer(params["before"]))
      |> maybe_put(:limit, params["limit"] && String.to_integer(params["limit"]))

    {:ok, entries, next_cursor} =
      Rexplorer.InternalTransactions.list_by_address(chain_id, hash, opts)

    json(conn, %{
      data: Enum.map(entries, &entry_json/1),
      next_cursor: next_cursor
    })
  end

  defp entry_json(entry) do
    %{
      transaction_hash: entry.transaction_hash,
      block_number: entry.block_number,
      trace_index: entry.trace_index,
      from_address: entry.from_address,
      to_address: entry.to_address,
      value: to_string(entry.value),
      call_type: entry.call_type,
      trace_address: entry.trace_address
    }
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
