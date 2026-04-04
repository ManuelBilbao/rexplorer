defmodule RexplorerWeb.Internal.AddressOverviewController do
  use RexplorerWeb, :controller
  action_fallback RexplorerWeb.FallbackController

  def show(conn, %{"address_hash" => hash, "chain_slug" => slug}) do
    with {:ok, chain} <- Rexplorer.Chains.get_chain_by_slug(slug),
         {:ok, address, recent_txs, recent_transfers} <-
           Rexplorer.Addresses.get_address_overview(chain.chain_id, hash) do
      json(conn, %{
        address: %{
          hash: address.hash,
          is_contract: address.is_contract,
          label: address.label,
          first_seen_at: address.first_seen_at
        },
        recent_transactions:
          Enum.map(recent_txs, fn tx ->
            %{
              hash: tx.hash,
              from_address: tx.from_address,
              to_address: tx.to_address,
              value: to_string(tx.value),
              status: tx.status,
              block_number: if(Ecto.assoc_loaded?(tx.block), do: tx.block.block_number, else: nil)
            }
          end),
        recent_token_transfers:
          Enum.map(recent_transfers, fn t ->
            %{
              from_address: t.from_address,
              to_address: t.to_address,
              token_contract_address: t.token_contract_address,
              amount: to_string(t.amount),
              token_type: t.token_type
            }
          end)
      })
    end
  end
end
