defmodule RexplorerIndexer.FrameTransactionTest do
  use ExUnit.Case, async: true

  alias RexplorerIndexer.BlockProcessor

  @frame_tx %{
    "hash" => "0xframe_tx_1",
    "type" => "0x6",
    "sender" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    "from" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    "nonce" => "0x1",
    "maxFeePerGas" => "0x77359400",
    "transactionIndex" => "0x0",
    "frames" => [
      %{
        "mode" => "0x1",
        "to" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "gasLimit" => "0x7a120",
        "data" => "0xabcdef"
      },
      %{
        "mode" => "0x2",
        "to" => "0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
        "gasLimit" => "0xc350",
        "data" => "0x"
      }
    ]
  }

  @frame_receipt %{
    "transactionHash" => "0xframe_tx_1",
    "status" => "0x1",
    "gasUsed" => "0x33791",
    "payer" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    "frameReceipts" => [
      %{"status" => "0x1", "gasUsed" => "0x2108e", "logs" => []},
      %{"status" => "0x1", "gasUsed" => "0x13", "logs" => []}
    ]
  }

  @regular_tx %{
    "hash" => "0xregular_tx_1",
    "type" => "0x2",
    "from" => "0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
    "to" => "0xDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
    "value" => "0x0",
    "input" => "0x",
    "gasPrice" => "0x3B9ACA00",
    "nonce" => "0x0",
    "transactionIndex" => "0x1"
  }

  @regular_receipt %{
    "transactionHash" => "0xregular_tx_1",
    "status" => "0x1",
    "gasUsed" => "0x5208",
    "logs" => []
  }

  @sample_block %{
    "number" => "0x1",
    "hash" => "0xblock_hash",
    "parentHash" => "0xparent_hash",
    "timestamp" => "0x5F5E100",
    "gasUsed" => "0x5208",
    "gasLimit" => "0x1C9C380",
    "baseFeePerGas" => "0x3B9ACA00",
    "transactions" => [@frame_tx, @regular_tx]
  }

  describe "is_frame_tx?/1" do
    test "detects type 0x6" do
      assert BlockProcessor.is_frame_tx?(%{"type" => "0x6"})
    end

    test "rejects regular tx" do
      assert not BlockProcessor.is_frame_tx?(%{"type" => "0x2"})
    end

    test "handles nil" do
      assert not BlockProcessor.is_frame_tx?(nil)
    end
  end

  describe "extract_frame_transaction/4" do
    test "extracts sender, nil to, zero value, payer" do
      tx = BlockProcessor.extract_frame_transaction(@frame_tx, @frame_receipt, 1, Rexplorer.Chain.Ethereum)

      assert tx.from_address == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      assert tx.to_address == nil
      assert Decimal.equal?(tx.value, Decimal.new(0))
      assert tx.transaction_type == 6
      assert tx.payer == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    end
  end

  describe "extract_frames/3" do
    test "extracts frames with mode, target, gas" do
      frames = BlockProcessor.extract_frames(@frame_tx, @frame_receipt, 1)

      assert length(frames) == 2

      [f0, f1] = frames
      assert f0.frame_index == 0
      assert f0.mode == 1
      assert f0.target == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      assert f0.gas_limit == 500_000
      assert f0.gas_used == 135_310
      assert f0.status == true

      assert f1.frame_index == 1
      assert f1.mode == 2
      assert f1.target == "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    end
  end

  describe "process_block/3 with mixed txs" do
    test "processes both frame and regular txs" do
      result = BlockProcessor.process_block(
        @sample_block,
        [@frame_receipt, @regular_receipt],
        Rexplorer.Chain.Ethereum
      )

      assert length(result.transactions) == 2
      assert length(result.frames) == 2

      # Frame tx
      frame_tx = Enum.find(result.transactions, &(&1.hash == "0xframe_tx_1"))
      assert frame_tx.to_address == nil
      assert frame_tx.transaction_type == 6
      assert frame_tx.payer == "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

      # Regular tx
      regular_tx = Enum.find(result.transactions, &(&1.hash == "0xregular_tx_1"))
      assert regular_tx.to_address == "0xdddddddddddddddddddddddddddddddddddddddd"
      assert Map.get(regular_tx, :payer) == nil
    end
  end
end
