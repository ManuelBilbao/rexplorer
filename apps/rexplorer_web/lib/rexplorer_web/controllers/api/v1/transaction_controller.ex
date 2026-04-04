defmodule RexplorerWeb.API.V1.TransactionController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Transactions"]

  operation :index,
    summary: "List transactions",
    description: "Returns a paginated list of transactions, optionally filtered by address.",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      address: [in: :query, type: :string, description: "Filter by sender or recipient address"],
      before_block: [in: :query, type: :integer, description: "Block number cursor"],
      before_index: [in: :query, type: :integer, description: "Transaction index cursor (within block)"],
      limit: [in: :query, type: :integer, description: "Max results (default 25, max 100)"]
    ],
    responses: [
      ok: {"Transaction list", "application/json", RexplorerWeb.Schemas.TransactionListResponse}
    ]

  def index(conn, params) do
    chain_id = conn.assigns.chain_id
    opts = parse_tx_pagination(params)

    {:ok, txs, next_cursor} = Rexplorer.Transactions.list_transactions(chain_id, opts)

    json(conn, %{
      data: Enum.map(txs, &tx_json/1),
      next_cursor: next_cursor
    })
  end

  operation :show,
    summary: "Get transaction by hash",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      hash: [in: :path, type: :string, description: "Transaction hash (0x-prefixed)", required: true]
    ],
    responses: [
      ok: {"Transaction detail", "application/json", RexplorerWeb.Schemas.TransactionResponse},
      not_found: {"Not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def show(conn, %{"hash" => hash}) do
    chain_id = conn.assigns.chain_id

    case Rexplorer.Transactions.get_transaction(chain_id, hash) do
      {:ok, tx} -> json(conn, %{data: tx_json(tx)})
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp tx_json(tx) do
    %{
      hash: tx.hash,
      from_address: tx.from_address,
      to_address: tx.to_address,
      value: to_string(tx.value),
      gas_price: tx.gas_price,
      gas_used: tx.gas_used,
      nonce: tx.nonce,
      status: tx.status,
      transaction_type: tx.transaction_type,
      transaction_index: tx.transaction_index,
      block_number: if(Ecto.assoc_loaded?(tx.block), do: tx.block.block_number, else: nil),
      chain_extra: tx.chain_extra
    }
  end

  defp parse_tx_pagination(params) do
    opts = []
    opts = if params["address"], do: [{:address, params["address"]} | opts], else: opts
    opts = if params["before_block"], do: [{:before_block, parse_int(params["before_block"])} | opts], else: opts
    opts = if params["before_index"], do: [{:before_index, parse_int(params["before_index"])} | opts], else: opts
    opts = if params["limit"], do: [{:limit, parse_int(params["limit"])} | opts], else: opts
    opts
  end

  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n) when is_integer(n), do: n
end
