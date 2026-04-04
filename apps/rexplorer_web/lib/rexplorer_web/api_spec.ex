defmodule RexplorerWeb.ApiSpec do
  @moduledoc "OpenAPI specification for the Rexplorer public API."

  alias OpenApiSpex.{Info, OpenApi, Paths, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Rexplorer API",
        version: "1.0.0",
        description: """
        Public REST API for querying blockchain data across multiple Ethereum-compatible chains.

        ## Pagination

        List endpoints use semantic cursor-based pagination. Each resource type uses its natural
        ordering key as the cursor. Default limit is 25, maximum is 100.

        ## Chain Routing

        Most endpoints are scoped to a chain via the `chain_slug` path parameter
        (e.g., `ethereum`, `optimism`, `base`).
        """
      },
      servers: [
        %Server{url: "/", description: "Rexplorer API"}
      ],
      paths: Paths.from_router(RexplorerWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
