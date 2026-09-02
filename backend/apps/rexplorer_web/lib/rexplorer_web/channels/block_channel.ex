defmodule RexplorerWeb.BlockChannel do
  @moduledoc """
  Channel for real-time new block notifications.

  Clients join `blocks:<chain_slug>` to receive `new_block` events
  whenever a new block is indexed for that chain.
  """

  use Phoenix.Channel

  @impl true
  def join("blocks:" <> chain_slug, _params, socket) do
    case Rexplorer.Chains.get_chain_by_slug(chain_slug) do
      {:ok, chain} ->
        Phoenix.PubSub.subscribe(Rexplorer.PubSub, "chain:#{chain.chain_id}:blocks")
        {:ok, assign(socket, :chain_id, chain.chain_id)}

      {:error, :not_found} ->
        {:error, %{reason: "unknown chain"}}
    end
  end

  @impl true
  def handle_info({:new_block, block_data}, socket) do
    push(socket, "new_block", block_data)
    {:noreply, socket}
  end
end
