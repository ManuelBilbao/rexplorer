defmodule Rexplorer.Chains do
  @moduledoc """
  Query module for chain records.

  Provides functions to list and look up supported blockchain networks.
  """

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Chain}

  @doc "Returns all enabled chains."
  def list_enabled_chains do
    Chain
    |> where([c], c.enabled == true)
    |> order_by([c], c.chain_id)
    |> Repo.all()
  end

  @doc "Returns a chain by its explorer slug."
  def get_chain_by_slug(slug) do
    case Repo.get_by(Chain, explorer_slug: slug) do
      nil -> {:error, :not_found}
      chain -> {:ok, chain}
    end
  end
end
