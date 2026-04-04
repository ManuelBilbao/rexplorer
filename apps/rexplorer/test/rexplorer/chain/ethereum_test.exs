defmodule Rexplorer.Chain.EthereumTest do
  use ExUnit.Case, async: true

  alias Rexplorer.Chain.Ethereum

  describe "chain metadata" do
    test "chain_id returns 1" do
      assert Ethereum.chain_id() == 1
    end

    test "chain_type returns :l1" do
      assert Ethereum.chain_type() == :l1
    end

    test "native_token returns ETH with 18 decimals" do
      assert Ethereum.native_token() == {"ETH", 18}
    end

    test "block_fields returns empty list" do
      assert Ethereum.block_fields() == []
    end

    test "transaction_fields returns empty list" do
      assert Ethereum.transaction_fields() == []
    end

    test "bridge_contracts returns empty list" do
      assert Ethereum.bridge_contracts() == []
    end

    test "poll_interval_ms returns 12_000" do
      assert Ethereum.poll_interval_ms() == 12_000
    end
  end

  describe "extract_operations/1" do
    test "produces a single call operation for a standard transaction" do
      tx = %{
        from_address: "0x7a250d5630b4cf539739df2c5dacb4c659f2488d",
        to_address: "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        value: Decimal.new("1000000000000000000"),
        input: <<0x38, 0xED, 0x17, 0x39>>
      }

      assert [operation] = Ethereum.extract_operations(tx)
      assert operation.operation_type == :call
      assert operation.operation_index == 0
      assert operation.from_address == tx.from_address
      assert operation.to_address == tx.to_address
      assert operation.value == tx.value
      assert operation.input == tx.input
    end
  end

  describe "extract_token_transfers/1" do
    test "extracts native ETH transfer" do
      tx = %{
        from_address: "0xaaaa",
        to_address: "0xbbbb",
        value: Decimal.new("1000000000000000000"),
        logs: []
      }

      assert [transfer] = Ethereum.extract_token_transfers(tx)
      assert transfer.token_type == :native
      assert transfer.from_address == "0xaaaa"
      assert transfer.to_address == "0xbbbb"
      assert Decimal.eq?(transfer.amount, Decimal.new("1000000000000000000"))
    end

    test "extracts ERC-20 transfer from logs" do
      tx = %{
        from_address: "0xaaaa",
        to_address: "0xcccc",
        value: Decimal.new(0),
        logs: [
          %{
            topic0: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
            topic1: "0x000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            topic2: "0x000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            data: "0x0000000000000000000000000000000000000000000000000de0b6b3a7640000",
            contract_address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
          }
        ]
      }

      assert [transfer] = Ethereum.extract_token_transfers(tx)
      assert transfer.token_type == :erc20
      assert transfer.from_address == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      assert transfer.to_address == "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      assert transfer.token_contract_address == "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
      assert Decimal.eq?(transfer.amount, Decimal.new("1000000000000000000"))
    end

    test "returns empty list for zero-value tx with no transfer events" do
      tx = %{
        from_address: "0xaaaa",
        to_address: "0xbbbb",
        value: Decimal.new(0),
        logs: []
      }

      assert [] = Ethereum.extract_token_transfers(tx)
    end

    test "extracts both native and ERC-20 transfers" do
      tx = %{
        from_address: "0xaaaa",
        to_address: "0xbbbb",
        value: Decimal.new("500"),
        logs: [
          %{
            topic0: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
            topic1: "0x000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            topic2: "0x000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            data: "0x00000000000000000000000000000000000000000000000000000000000003e8",
            contract_address: "0xtoken"
          }
        ]
      }

      transfers = Ethereum.extract_token_transfers(tx)
      assert length(transfers) == 2
      assert Enum.any?(transfers, &(&1.token_type == :native))
      assert Enum.any?(transfers, &(&1.token_type == :erc20))
    end
  end
end
