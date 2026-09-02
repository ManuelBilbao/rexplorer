defmodule RexplorerWeb.Internal.InternalTransactionController do
  @moduledoc """
  BFF endpoint for address internal transactions.

  Serves `GET /internal/chains/:chain_slug/addresses/:address_hash/internal-transactions`
  returning paginated internal transactions (value-transferring trace entries)
  for an address.

  ## Query Parameters

  - `before` — block_number cursor for pagination
  - `limit` — max results (default 25, max 100)
  """

  use RexplorerWeb, :controller
  action_fallback RexplorerWeb.FallbackController

  def index(conn, %{"address_hash" => hash, "chain_slug" => slug} = params) do
    with {:ok, chain} <- Rexplorer.Chains.get_chain_by_slug(slug) do
      opts =
        []
        |> maybe_put(:before, params["before"] && String.to_integer(params["before"]))
        |> maybe_put(:limit, params["limit"] && String.to_integer(params["limit"]))

      {:ok, entries, next_cursor} =
        Rexplorer.InternalTransactions.list_by_address(chain.chain_id, hash, opts)

      json(conn, %{
        data: Enum.map(entries, &entry_json/1),
        next_cursor: next_cursor
      })
    end
  end

  defp entry_json(entry) do
    %{
      transaction_hash: entry.transaction_hash,
      block_number: entry.block_number,
      trace_index: entry.trace_index,
      from_address: entry.from_address,
      to_address: entry.to_address,
      value: to_string(entry.value),
      call_type: entry.call_type,
      trace_address: entry.trace_address
    }
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
