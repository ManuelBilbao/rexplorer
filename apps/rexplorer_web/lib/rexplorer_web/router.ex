defmodule RexplorerWeb.Router do
  use RexplorerWeb, :router

  pipeline :public_api do
    plug :accepts, ["json"]
    plug CORSPlug
    plug OpenApiSpex.Plug.PutApiSpec, module: RexplorerWeb.ApiSpec
    plug RexplorerWeb.Plugs.ChainSlug
  end

  pipeline :internal_api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  # OpenAPI spec and Swagger UI
  scope "/api" do
    pipe_through :public_api
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/swaggerui" do
    get "/", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  # Public REST API — stable, versioned, for external consumers
  scope "/api/v1", RexplorerWeb.API.V1 do
    pipe_through :public_api

    resources "/chains", ChainController, only: [:index, :show], param: "slug"

    scope "/chains/:chain_slug" do
      resources "/blocks", BlockController, only: [:index, :show], param: "number"

      resources "/transactions", TransactionController, only: [:index, :show], param: "hash" do
        resources "/operations", OperationController, only: [:index]
      end

      scope "/addresses/:address_hash" do
        get "/", AddressController, :show
        get "/token-transfers", TokenTransferController, :index
      end
    end
  end

  # Backend-for-Frontend API — UI-optimized, free to evolve
  scope "/internal", RexplorerWeb.Internal do
    pipe_through :internal_api

    get "/search", SearchController, :index

    scope "/chains/:chain_slug" do
      get "/home", HomeController, :show
      get "/transactions/:hash", TransactionDetailController, :show
      get "/addresses/:address_hash", AddressOverviewController, :show
    end
  end
end
