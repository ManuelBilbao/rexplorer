defmodule RexplorerWeb.API.V1.TokenTransferController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Token Transfers"]

  operation :index,
    summary: "List token transfers for an address",
    description: "Returns paginated token transfers (ERC-20, ERC-721, native) involving the address as sender or recipient.",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      address_hash: [in: :path, type: :string, required: true],
      before: [in: :query, type: :integer, description: "ID cursor for pagination"],
      limit: [in: :query, type: :integer, description: "Max results (default 25, max 100)"]
    ],
    responses: [
      ok: {"Token transfer list", "application/json", RexplorerWeb.Schemas.TokenTransferListResponse}
    ]

  def index(conn, %{"address_hash" => address_hash} = params) do
    chain_id = conn.assigns.chain_id
    opts = parse_pagination(params)

    {:ok, transfers, next_cursor} =
      Rexplorer.Addresses.list_token_transfers(chain_id, address_hash, opts)

    json(conn, %{
      data: Enum.map(transfers, &transfer_json/1),
      next_cursor: next_cursor
    })
  end

  defp transfer_json(transfer) do
    %{
      from_address: transfer.from_address,
      to_address: transfer.to_address,
      token_contract_address: transfer.token_contract_address,
      amount: to_string(transfer.amount),
      token_type: transfer.token_type,
      token_id: transfer.token_id
    }
  end

  defp parse_pagination(params) do
    opts = []
    opts = if params["before"], do: [{:before, String.to_integer(params["before"])} | opts], else: opts
    opts = if params["limit"], do: [{:limit, String.to_integer(params["limit"])} | opts], else: opts
    opts
  end
end
