defmodule Rexplorer.BalancesTest do
  use Rexplorer.DataCase, async: true

  alias Rexplorer.{Balances, Schema.Chain, Schema.Address, Schema.BalanceChange}

  @chain_id 99991

  setup do
    chain =
      case Repo.get(Chain, @chain_id) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: @chain_id,
            name: "Balance Test Chain",
            chain_type: :l1,
            native_token_symbol: "ETH",
            explorer_slug: "balance-test"
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
        current_balance_wei: Decimal.new("5000000000000000000")
      })
      |> Repo.insert!()

    %{chain: chain, address: address}
  end

  describe "get_current_balance/2" do
    test "returns balance for known address", %{address: address} do
      assert {:ok, balance} = Balances.get_current_balance(@chain_id, address.hash)
      assert Decimal.equal?(balance, Decimal.new("5000000000000000000"))
    end

    test "returns not_found for unknown address" do
      assert {:error, :not_found} = Balances.get_current_balance(@chain_id, "0x0000000000000000000000000000000000000000")
    end

    test "returns nil balance for address with no balance data" do
      %Address{}
      |> Address.changeset(%{
        chain_id: @chain_id,
        hash: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        first_seen_at: ~U[2025-01-01 00:00:00Z]
      })
      |> Repo.insert!()

      assert {:ok, nil} = Balances.get_current_balance(@chain_id, "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    end
  end

  describe "get_balance_history/3" do
    setup %{address: address} do
      entries =
        for i <- 1..10 do
          %BalanceChange{}
          |> BalanceChange.changeset(%{
            chain_id: @chain_id,
            address_hash: address.hash,
            block_number: 100 + i,
            balance_wei: Decimal.new(to_string(i * 1_000_000_000_000_000_000)),
            timestamp: DateTime.add(~U[2025-01-01 00:00:00Z], i * 12, :second),
            source: if(i == 1, do: "seed", else: "indexed")
          })
          |> Repo.insert!()
        end

      %{entries: entries}
    end

    test "returns all entries ordered by block_number ascending", %{address: address} do
      {:ok, entries, nil} = Balances.get_balance_history(@chain_id, address.hash)

      assert length(entries) == 10
      assert hd(entries).block_number == 101
      assert List.last(entries).block_number == 110
    end

    test "supports limit option", %{address: address} do
      {:ok, entries, next_cursor} = Balances.get_balance_history(@chain_id, address.hash, limit: 3)

      assert length(entries) == 3
      assert next_cursor == 103
    end

    test "supports before cursor", %{address: address} do
      {:ok, entries, _} = Balances.get_balance_history(@chain_id, address.hash, before: 105)

      block_numbers = Enum.map(entries, & &1.block_number)
      assert Enum.all?(block_numbers, &(&1 < 105))
    end

    test "returns empty list for address with no history" do
      {:ok, [], nil} = Balances.get_balance_history(@chain_id, "0xcccccccccccccccccccccccccccccccccccccccc")
    end
  end
end
