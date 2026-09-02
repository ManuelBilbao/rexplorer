defmodule RexplorerWeb.BalanceHistoryTest do
  use RexplorerWeb.ConnCase, async: true

  alias Rexplorer.{Repo, Schema.Chain, Schema.Address, Schema.BalanceChange}

  @chain_id 99992

  setup %{conn: conn} do
    chain =
      case Repo.get(Chain, @chain_id) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: @chain_id,
            name: "BH Test Chain",
            chain_type: :l1,
            native_token_symbol: "ETH",
            explorer_slug: "bh-test"
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    address =
      %Address{}
      |> Address.changeset(%{
        chain_id: @chain_id,
        hash: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        first_seen_at: ~U[2025-01-01 00:00:00Z],
        current_balance_wei: Decimal.new("3000000000000000000")
      })
      |> Repo.insert!()

    for i <- 1..5 do
      %BalanceChange{}
      |> BalanceChange.changeset(%{
        chain_id: @chain_id,
        address_hash: address.hash,
        block_number: 100 + i,
        balance_wei: Decimal.new(to_string(i * 1_000_000_000_000_000_000)),
        timestamp: DateTime.add(~U[2025-01-01 00:00:00Z], i * 12, :second),
        source: "indexed"
      })
      |> Repo.insert!()
    end

    %{conn: conn, chain: chain, address: address}
  end

  describe "GET /internal/chains/:slug/addresses/:hash/balance-history" do
    test "returns balance history", %{conn: conn, address: address} do
      conn = get(conn, "/internal/chains/bh-test/addresses/#{address.hash}/balance-history")

      assert %{"data" => data, "next_cursor" => nil} = json_response(conn, 200)
      assert length(data) == 5
      assert hd(data)["block_number"] == 101
    end

    test "supports pagination", %{conn: conn, address: address} do
      conn = get(conn, "/internal/chains/bh-test/addresses/#{address.hash}/balance-history?limit=2")

      assert %{"data" => data, "next_cursor" => cursor} = json_response(conn, 200)
      assert length(data) == 2
      assert is_integer(cursor)
    end

    test "returns empty for unknown address", %{conn: conn} do
      conn = get(conn, "/internal/chains/bh-test/addresses/0x0000000000000000000000000000000000099999/balance-history")

      assert %{"data" => [], "next_cursor" => nil} = json_response(conn, 200)
    end

    test "returns 404 for unknown chain", %{conn: conn} do
      conn = get(conn, "/internal/chains/nonexistent/addresses/0xaaa/balance-history")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/v1/chains/:slug/addresses/:hash/balance-history" do
    test "returns balance history via public API", %{conn: conn, address: address} do
      conn = get(conn, "/api/v1/chains/bh-test/addresses/#{address.hash}/balance-history")

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 5
    end
  end
end
