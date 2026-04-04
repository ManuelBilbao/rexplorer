defmodule RexplorerWeb.Internal.SearchController do
  use RexplorerWeb, :controller

  def index(conn, %{"q" => query} = params) do
    chain_id =
      case params["chain"] do
        nil -> nil
        slug ->
          case Rexplorer.Chains.get_chain_by_slug(slug) do
            {:ok, chain} -> chain.chain_id
            _ -> nil
          end
      end

    {:ok, result} = Rexplorer.Search.query(query, chain_id: chain_id)

    json(conn, %{
      type: result.type,
      results: format_results(result.type, result.results)
    })
  end

  def index(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "bad_request", message: "Missing required parameter: q"})
  end

  defp format_results(:transaction, txs) do
    Enum.map(txs, fn tx ->
      %{
        hash: tx.hash,
        chain_id: tx.chain_id,
        block_number: if(Ecto.assoc_loaded?(tx.block), do: tx.block.block_number, else: nil)
      }
    end)
  end

  defp format_results(:address, addresses) do
    Enum.map(addresses, fn a ->
      %{hash: a.hash, chain_id: a.chain_id, is_contract: a.is_contract, label: a.label}
    end)
  end

  defp format_results(:block_number, blocks) do
    Enum.map(blocks, fn b ->
      %{block_number: b.block_number, chain_id: b.chain_id, hash: b.hash}
    end)
  end

  defp format_results(_, _), do: []
end
