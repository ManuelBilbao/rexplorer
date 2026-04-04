defmodule RexplorerWeb.AddressChannel do
  @moduledoc """
  Channel for real-time address activity notifications.

  Clients join `address:<chain_slug>:<address_hash>` to receive events
  when the address is involved in a new transaction or token transfer.
  """

  use Phoenix.Channel

  @impl true
  def join("address:" <> rest, _params, socket) do
    case String.split(rest, ":", parts: 2) do
      [chain_slug, address_hash] ->
        case Rexplorer.Chains.get_chain_by_slug(chain_slug) do
          {:ok, chain} ->
            address_hash = String.downcase(address_hash)
            topic = "chain:#{chain.chain_id}:address:#{address_hash}"
            Phoenix.PubSub.subscribe(Rexplorer.PubSub, topic)

            {:ok,
             socket
             |> assign(:chain_id, chain.chain_id)
             |> assign(:address_hash, address_hash)}

          {:error, :not_found} ->
            {:error, %{reason: "unknown chain"}}
        end

      _ ->
        {:error, %{reason: "invalid topic format, expected address:<chain>:<hash>"}}
    end
  end

  @impl true
  def handle_info({:new_transaction, tx_data}, socket) do
    push(socket, "new_transaction", tx_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_token_transfer, transfer_data}, socket) do
    push(socket, "new_token_transfer", transfer_data)
    {:noreply, socket}
  end
end
