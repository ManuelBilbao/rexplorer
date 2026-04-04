defmodule RexplorerWeb.UserSocket do
  use Phoenix.Socket

  channel "blocks:*", RexplorerWeb.BlockChannel
  channel "address:*", RexplorerWeb.AddressChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
