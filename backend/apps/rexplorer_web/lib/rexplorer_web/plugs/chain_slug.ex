defmodule RexplorerWeb.Plugs.ChainSlug do
  @moduledoc """
  Resolves the `:chain_slug` path parameter to a `chain_id` integer.

  If the slug is found, assigns `chain_id` and `chain` to the connection.
  This plug is a no-op if no `:chain_slug` param is present (e.g., on
  the `/chains` index endpoint).
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(%{params: %{"chain_slug" => slug}} = conn, _opts) do
    case Rexplorer.Chains.get_chain_by_slug(slug) do
      {:ok, chain} ->
        conn
        |> assign(:chain_id, chain.chain_id)
        |> assign(:chain, chain)

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> Phoenix.Controller.json(%{error: "not_found", message: "Chain not found"})
        |> halt()
    end
  end

  def call(conn, _opts), do: conn
end
