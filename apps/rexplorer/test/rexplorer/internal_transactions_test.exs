defmodule Rexplorer.InternalTransactionsTest do
  use Rexplorer.DataCase, async: true

  alias Rexplorer.{InternalTransactions, Schema.Chain, Schema.InternalTransaction}

  @chain_id 99993

  setup do
    chain =
      case Repo.get(Chain, @chain_id) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: @chain_id,
            name: "Internal Tx Test Chain",
            chain_type: :zk_rollup,
            native_token_symbol: "ETH",
            explorer_slug: "itx-test"
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    # Insert test internal transactions
    for i <- 1..10 do
      %InternalTransaction{}
      |> InternalTransaction.changeset(%{
        chain_id: @chain_id,
        block_number: 100 + i,
        transaction_hash: "0xtx_#{i}",
        transaction_index: 0,
        trace_index: i - 1,
        from_address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        to_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        value: Decimal.new(to_string(i * 1_000_000_000_000_000_000)),
        call_type: "call",
        trace_address: [0]
      })
      |> Repo.insert!()
    end

    %{chain: chain}
  end

  describe "list_by_address/3" do
    test "finds internal transactions by from_address" do
      {:ok, entries, _} = InternalTransactions.list_by_address(@chain_id, "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      assert length(entries) == 10
    end

    test "finds internal transactions by to_address" do
      {:ok, entries, _} = InternalTransactions.list_by_address(@chain_id, "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
      assert length(entries) == 10
    end

    test "supports limit" do
      {:ok, entries, cursor} = InternalTransactions.list_by_address(@chain_id, "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", limit: 3)
      assert length(entries) == 3
      assert is_integer(cursor)
    end

    test "supports before cursor" do
      {:ok, entries, _} = InternalTransactions.list_by_address(@chain_id, "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", before: 105)
      block_numbers = Enum.map(entries, & &1.block_number)
      assert Enum.all?(block_numbers, &(&1 < 105))
    end

    test "returns empty for unknown address" do
      {:ok, [], nil} = InternalTransactions.list_by_address(@chain_id, "0x0000000000000000000000000000000000099999")
    end

    test "results ordered by block_number descending" do
      {:ok, entries, _} = InternalTransactions.list_by_address(@chain_id, "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      block_numbers = Enum.map(entries, & &1.block_number)
      assert block_numbers == Enum.sort(block_numbers, :desc)
    end
  end
end
