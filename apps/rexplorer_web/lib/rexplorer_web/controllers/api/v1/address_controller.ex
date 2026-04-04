defmodule RexplorerWeb.API.V1.AddressController do
  use RexplorerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  action_fallback RexplorerWeb.FallbackController

  tags ["Addresses"]

  operation :show,
    summary: "Get address",
    description: "Returns metadata for an address on a specific chain.",
    parameters: [
      chain_slug: [in: :path, type: :string, required: true],
      address_hash: [in: :path, type: :string, description: "Address (0x-prefixed, 42 chars)", required: true]
    ],
    responses: [
      ok: {"Address detail", "application/json", RexplorerWeb.Schemas.AddressResponse},
      not_found: {"Not found", "application/json", RexplorerWeb.Schemas.ErrorResponse}
    ]

  def show(conn, %{"address_hash" => hash}) do
    chain_id = conn.assigns.chain_id

    case Rexplorer.Addresses.get_address(chain_id, hash) do
      {:ok, address} -> json(conn, %{data: address_json(address)})
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp address_json(address) do
    %{
      hash: address.hash,
      is_contract: address.is_contract,
      label: address.label,
      first_seen_at: address.first_seen_at
    }
  end
end
