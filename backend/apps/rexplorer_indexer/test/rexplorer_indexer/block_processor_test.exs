defmodule RexplorerIndexer.BlockProcessorTest do
  use ExUnit.Case, async: true

  alias RexplorerIndexer.BlockProcessor

  @sample_block %{
    "number" => "0xF4240",
    "hash" => "0xblock_hash_abc",
    "parentHash" => "0xparent_hash_def",
    "timestamp" => "0x5F5E100",
    "gasUsed" => "0x5208",
    "gasLimit" => "0x1C9C380",
    "baseFeePerGas" => "0x3B9ACA00",
    "transactions" => [
      %{
        "hash" => "0xtx_hash_1",
        "from" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "to" => "0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
        "value" => "0xDE0B6B3A7640000",
        "input" => "0x",
        "gasPrice" => "0x3B9ACA00",
        "nonce" => "0x5",
        "type" => "0x2",
        "transactionIndex" => "0x0"
      }
    ]
  }

  @sample_receipts [
    %{
      "transactionHash" => "0xtx_hash_1",
      "status" => "0x1",
      "gasUsed" => "0x5208",
      "logs" => []
    }
  ]

  describe "process_block/3" do
    test "processes a standard block with one transaction" do
      result = BlockProcessor.process_block(@sample_block, @sample_receipts, Rexplorer.Chain.Ethereum)

      assert result.block.chain_id == 1
      assert result.block.block_number == 1_000_000
      assert result.block.hash == "0xblock_hash_abc"
      assert result.block.parent_hash == "0xparent_hash_def"
      assert result.block.gas_used == 21_000

      assert length(result.transactions) == 1
      [tx] = result.transactions
      assert tx.hash == "0xtx_hash_1"
      assert tx.from_address == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      assert tx.to_address == "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      assert tx.status == true
      assert tx.gas_used == 21_000
      assert tx.nonce == 5

      assert length(result.operations) == 1
      [op] = result.operations
      assert op.operation_type == :call
      assert op.chain_id == 1

      # Native transfer (value > 0)
      assert length(result.token_transfers) == 1
      [xfer] = result.token_transfers
      assert xfer.token_type == :native
      assert xfer.chain_id == 1
    end

    test "handles contract creation (to = null)" do
      block = put_in(@sample_block, ["transactions", Access.at(0), "to"], nil)

      result = BlockProcessor.process_block(block, @sample_receipts, Rexplorer.Chain.Ethereum)

      [tx] = result.transactions
      assert tx.to_address == nil
    end

    test "discovers unique addresses" do
      result = BlockProcessor.process_block(@sample_block, @sample_receipts, Rexplorer.Chain.Ethereum)

      address_hashes = Enum.map(result.addresses, & &1.hash)
      assert "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in address_hashes
      assert "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" in address_hashes
      # No duplicates
      assert length(address_hashes) == length(Enum.uniq(address_hashes))
    end

    test "deduplicates addresses across transactions" do
      # Add a second tx with the same from_address
      second_tx = %{
        "hash" => "0xtx_hash_2",
        "from" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "to" => "0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
        "value" => "0x0",
        "input" => "0x",
        "gasPrice" => "0x3B9ACA00",
        "nonce" => "0x6",
        "type" => "0x2",
        "transactionIndex" => "0x1"
      }

      second_receipt = %{
        "transactionHash" => "0xtx_hash_2",
        "status" => "0x1",
        "gasUsed" => "0x5208",
        "logs" => []
      }

      block = Map.update!(@sample_block, "transactions", &(&1 ++ [second_tx]))
      receipts = @sample_receipts ++ [second_receipt]

      result = BlockProcessor.process_block(block, receipts, Rexplorer.Chain.Ethereum)

      address_hashes = Enum.map(result.addresses, & &1.hash)
      # 0xaaaa appears in both txs but should only be listed once
      assert length(Enum.filter(address_hashes, &(&1 == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))) == 1
      # 3 unique addresses: 0xaaaa, 0xbbbb, 0xcccc
      assert length(address_hashes) == 3
    end

    test "extracts ERC-20 transfers from logs" do
      receipt_with_transfer = %{
        "transactionHash" => "0xtx_hash_1",
        "status" => "0x1",
        "gasUsed" => "0x5208",
        "logs" => [
          %{
            "logIndex" => "0x0",
            "address" => "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            "topics" => [
              "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
              "0x000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
              "0x000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            ],
            "data" => "0x00000000000000000000000000000000000000000000000000000000000003e8"
          }
        ]
      }

      result = BlockProcessor.process_block(@sample_block, [receipt_with_transfer], Rexplorer.Chain.Ethereum)

      erc20_transfers = Enum.filter(result.token_transfers, &(&1.token_type == :erc20))
      assert length(erc20_transfers) == 1
      [xfer] = erc20_transfers
      assert Decimal.eq?(xfer.amount, Decimal.new(1000))
    end
  end
end
