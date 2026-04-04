defmodule RexplorerWeb.API.V1.ChainController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Chains"]

  operation :index,
    summary: "List all chains",
    description: "Returns all enabled blockchain networks supported by this explorer.",
    responses: [
      ok: {"Chain list", "application/json", RexplorerWeb.Schemas.ChainListResponse}
    ]

  def index(conn, _params) do
    chains = Rexplorer.Chains.list_enabled_chains()
    json(conn, %{data: Enum.map(chains, &chain_json/1)})
  end

  operation :show,
    summary: "Get chain by slug",
    description: "Returns details for a single chain identified by its explorer slug.",
    parameters: [
      slug: [in: :path, type: :string, description: "Chain explorer slug (e.g., ethereum, optimism)", required: true]
    ],
    responses: [
      ok: {"Chain detail", "application/json", RexplorerWeb.Schemas.ChainResponse},
      not_found: {"Not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def show(conn, %{"slug" => slug}) do
    case Rexplorer.Chains.get_chain_by_slug(slug) do
      {:ok, chain} -> json(conn, %{data: chain_json(chain)})
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp chain_json(chain) do
    %{
      chain_id: chain.chain_id,
      name: chain.name,
      chain_type: chain.chain_type,
      native_token_symbol: chain.native_token_symbol,
      explorer_slug: chain.explorer_slug
    }
  end
end
