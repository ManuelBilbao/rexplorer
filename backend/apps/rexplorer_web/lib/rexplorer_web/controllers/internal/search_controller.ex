defmodule RexplorerWeb.Internal.SearchController do
  use RexplorerWeb, :controller

  def index(conn, %{"q" => query} = params) do
    chain_id =
      case params["chain"] do
        nil ->
          nil

        slug ->
          case Rexplorer.Chains.get_chain_by_slug(slug) do
            {:ok, chain} -> chain.chain_id
            _ -> nil
          end
      end

    {:ok, result} = Rexplorer.Search.query(query, chain_id: chain_id)

    slugs = chain_slugs()
    results = format_results(result.type, result.results, slugs)

    json(conn, %{
      type: result.type,
      results: results,
      redirect: redirect_hint(result.type, results)
    })
  end

  def index(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "bad_request", message: "Missing required parameter: q"})
  end

  defp format_results(:transaction, txs, slugs) do
    Enum.map(txs, fn tx ->
      %{
        hash: tx.hash,
        chain_id: tx.chain_id,
        chain: slugs[tx.chain_id],
        block_number: if(Ecto.assoc_loaded?(tx.block), do: tx.block.block_number, else: nil)
      }
    end)
  end

  # A userOpHash resolves to its parent transaction: one entry per matching
  # operation, all pointing at the transaction the UserOperation was bundled in.
  defp format_results(:user_operation, operations, slugs) do
    Enum.map(operations, fn operation ->
      %{
        user_op_hash: operation.op_extra["user_op_hash"],
        user_op_index: operation.op_extra["user_op_index"],
        transaction_hash: operation.transaction.hash,
        chain_id: operation.chain_id,
        chain: slugs[operation.chain_id],
        block_number:
          if(Ecto.assoc_loaded?(operation.transaction.block),
            do: operation.transaction.block.block_number,
            else: nil
          )
      }
    end)
  end

  defp format_results(:address, addresses, slugs) do
    Enum.map(addresses, fn a ->
      %{
        hash: a.hash,
        chain_id: a.chain_id,
        chain: slugs[a.chain_id],
        is_contract: a.is_contract,
        label: a.label
      }
    end)
  end

  defp format_results(:block_number, blocks, slugs) do
    Enum.map(blocks, fn b ->
      %{
        block_number: b.block_number,
        chain_id: b.chain_id,
        chain: slugs[b.chain_id],
        hash: b.hash
      }
    end)
  end

  defp format_results(_, _, _), do: []

  # All operations sharing a userOpHash live in the same transaction, so a
  # match — however many operations it produced — is one place to go.
  defp redirect_hint(:user_operation, [%{chain: chain, transaction_hash: hash} | _])
       when is_binary(chain) do
    "/#{chain}/tx/#{hash}"
  end

  defp redirect_hint(_type, _results), do: nil

  defp chain_slugs do
    Rexplorer.Chains.list_enabled_chains()
    |> Map.new(fn chain -> {chain.chain_id, chain.explorer_slug} end)
  end
end
