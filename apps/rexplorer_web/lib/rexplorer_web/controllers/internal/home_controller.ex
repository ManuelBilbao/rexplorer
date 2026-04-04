defmodule RexplorerWeb.Internal.HomeController do
  use RexplorerWeb, :controller
  action_fallback RexplorerWeb.FallbackController

  def show(conn, %{"chain_slug" => slug}) do
    with {:ok, chain} <- Rexplorer.Chains.get_chain_by_slug(slug) do
      {:ok, blocks, _} = Rexplorer.Blocks.list_blocks(chain.chain_id, limit: 10)

      {:ok, txs, _} = Rexplorer.Transactions.list_transactions(chain.chain_id, limit: 10)

      json(conn, %{
        chain: %{
          chain_id: chain.chain_id,
          name: chain.name,
          explorer_slug: chain.explorer_slug
        },
        latest_blocks:
          Enum.map(blocks, fn b ->
            %{
              block_number: b.block_number,
              hash: b.hash,
              timestamp: b.timestamp,
              transaction_count: b.transaction_count
            }
          end),
        latest_transactions:
          Enum.map(txs, fn tx ->
            %{
              hash: tx.hash,
              from_address: tx.from_address,
              to_address: tx.to_address,
              value: to_string(tx.value),
              status: tx.status
            }
          end)
      })
    end
  end
end
