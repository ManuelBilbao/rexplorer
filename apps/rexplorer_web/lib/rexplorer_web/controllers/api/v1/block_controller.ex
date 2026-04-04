defmodule RexplorerWeb.API.V1.BlockController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Blocks"]

  operation :index,
    summary: "List blocks",
    description: "Returns a paginated list of blocks for a chain, in descending order by block number.",
    parameters: [
      chain_slug: [in: :path, type: :string, description: "Chain slug", required: true],
      before: [in: :query, type: :integer, description: "Return blocks before this block number (cursor)"],
      limit: [in: :query, type: :integer, description: "Max results (default 25, max 100)"]
    ],
    responses: [
      ok: {"Block list", "application/json", RexplorerWeb.Schemas.BlockListResponse}
    ]

  def index(conn, params) do
    chain_id = conn.assigns.chain_id
    opts = parse_block_pagination(params)

    {:ok, blocks, next_cursor} = Rexplorer.Blocks.list_blocks(chain_id, opts)

    json(conn, %{
      data: Enum.map(blocks, &block_json/1),
      next_cursor: next_cursor
    })
  end

  operation :show,
    summary: "Get block by number",
    description: "Returns a single block with its header fields and transaction count.",
    parameters: [
      chain_slug: [in: :path, type: :string, description: "Chain slug", required: true],
      number: [in: :path, type: :integer, description: "Block number", required: true]
    ],
    responses: [
      ok: {"Block detail", "application/json", RexplorerWeb.Schemas.BlockResponse},
      not_found: {"Not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def show(conn, %{"number" => number_str}) do
    chain_id = conn.assigns.chain_id

    case Integer.parse(number_str) do
      {number, ""} ->
        case Rexplorer.Blocks.get_block(chain_id, number) do
          {:ok, block} -> json(conn, %{data: block_json(block)})
          {:error, :not_found} -> {:error, :not_found}
        end

      _ ->
        {:error, :bad_request, "Invalid block number"}
    end
  end

  defp block_json(block) do
    %{
      block_number: block.block_number,
      hash: block.hash,
      parent_hash: block.parent_hash,
      timestamp: block.timestamp,
      gas_used: block.gas_used,
      gas_limit: block.gas_limit,
      base_fee_per_gas: block.base_fee_per_gas,
      transaction_count: block.transaction_count,
      chain_extra: block.chain_extra
    }
  end

  defp parse_block_pagination(params) do
    opts = []
    opts = if params["before"], do: [{:before, parse_int(params["before"])} | opts], else: opts
    opts = if params["limit"], do: [{:limit, parse_int(params["limit"])} | opts], else: opts
    opts
  end

  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n) when is_integer(n), do: n
end
