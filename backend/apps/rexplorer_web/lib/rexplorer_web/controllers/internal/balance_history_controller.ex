defmodule RexplorerWeb.Internal.BalanceHistoryController do
  @moduledoc """
  BFF endpoint for address balance history.

  Serves `GET /internal/chains/:chain_slug/addresses/:address_hash/balance-history`
  returning a time-ordered list of balance data points for charting.

  ## Query Parameters

  - `before` — block_number cursor for pagination
  - `limit` — max results (default 500, max 2000)
  """

  use RexplorerWeb, :controller
  action_fallback RexplorerWeb.FallbackController

  def index(conn, %{"address_hash" => hash, "chain_slug" => slug} = params) do
    with {:ok, chain} <- Rexplorer.Chains.get_chain_by_slug(slug) do
      opts =
        []
        |> maybe_put(:before, params["before"] && String.to_integer(params["before"]))
        |> maybe_put(:limit, params["limit"] && String.to_integer(params["limit"]))

      case Rexplorer.Balances.get_balance_history(chain.chain_id, hash, opts) do
        {:ok, entries, next_cursor} ->
          json(conn, %{
            data:
              Enum.map(entries, fn e ->
                %{
                  block_number: e.block_number,
                  balance_wei: to_string(e.balance_wei),
                  timestamp: e.timestamp
                }
              end),
            next_cursor: next_cursor
          })
      end
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
