defmodule Rexplorer.Chain.AdaptersTest do
  use ExUnit.Case, async: true

  @adapters [
    {Rexplorer.Chain.Ethereum, 1, :l1, {"ETH", 18}, 12_000},
    {Rexplorer.Chain.Optimism, 10, :optimistic_rollup, {"ETH", 18}, 2_000},
    {Rexplorer.Chain.Base, 8453, :optimistic_rollup, {"ETH", 18}, 2_000},
    {Rexplorer.Chain.BNB, 56, :sidechain, {"BNB", 18}, 3_000},
    {Rexplorer.Chain.Polygon, 137, :sidechain, {"POL", 18}, 2_000}
  ]

  for {mod, chain_id, chain_type, native_token, poll_interval} <- @adapters do
    describe "#{mod}" do
      test "chain_id returns #{chain_id}" do
        assert unquote(mod).chain_id() == unquote(chain_id)
      end

      test "chain_type returns #{chain_type}" do
        assert unquote(mod).chain_type() == unquote(chain_type)
      end

      test "native_token returns #{inspect(native_token)}" do
        assert unquote(mod).native_token() == unquote(Macro.escape(native_token))
      end

      test "poll_interval_ms returns #{poll_interval}" do
        assert unquote(mod).poll_interval_ms() == unquote(poll_interval)
      end

      test "extract_operations delegates to unwrapper" do
        tx = %{
          from_address: "0xaaaa",
          to_address: "0xbbbb",
          value: Decimal.new(0),
          input: <<0x12, 0x34, 0x56, 0x78>>
        }

        ops = unquote(mod).extract_operations(tx)
        assert [%{operation_type: :call}] = ops
      end

      test "extract_token_transfers handles native transfer" do
        tx = %{
          from_address: "0xaaaa",
          to_address: "0xbbbb",
          value: Decimal.new("1000000000000000000"),
          logs: []
        }

        transfers = unquote(mod).extract_token_transfers(tx)
        assert [%{token_type: :native}] = transfers
      end
    end
  end

  describe "OP Stack adapters" do
    test "Optimism has L2 block fields" do
      fields = Rexplorer.Chain.Optimism.block_fields()
      assert {:l1_block_number, :integer} in fields
      assert {:sequence_number, :integer} in fields
    end

    test "Optimism has deposit tx fields" do
      fields = Rexplorer.Chain.Optimism.transaction_fields()
      assert {:source_hash, :string} in fields
      assert {:mint, :integer} in fields
      assert {:is_system_tx, :boolean} in fields
    end

    test "Base has L2 block fields" do
      assert Rexplorer.Chain.Base.block_fields() == Rexplorer.Chain.Optimism.block_fields()
    end

    test "Base has deposit tx fields" do
      assert Rexplorer.Chain.Base.transaction_fields() == Rexplorer.Chain.Optimism.transaction_fields()
    end

    test "Optimism has bridge contracts" do
      assert length(Rexplorer.Chain.Optimism.bridge_contracts()) > 0
    end

    test "Base has bridge contracts" do
      assert length(Rexplorer.Chain.Base.bridge_contracts()) > 0
    end
  end

  describe "Sidechain adapters" do
    test "BNB has empty block fields" do
      assert Rexplorer.Chain.BNB.block_fields() == []
    end

    test "Polygon has empty block fields" do
      assert Rexplorer.Chain.Polygon.block_fields() == []
    end

    test "BNB has empty bridge contracts" do
      assert Rexplorer.Chain.BNB.bridge_contracts() == []
    end
  end
end
