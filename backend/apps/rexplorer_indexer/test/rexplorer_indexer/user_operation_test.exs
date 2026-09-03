defmodule RexplorerIndexer.UserOperationTest do
  use ExUnit.Case, async: true

  alias RexplorerIndexer.BlockProcessor

  @handle_ops_v07 "handleOps((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[],address)"
  @user_op_event_topic0 "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"
  @entry_point "0x0000000071727de22e5e9d8baf0edac6f37da032"

  defp addr(byte), do: :binary.copy(<<byte>>, 20)
  defp hex(binary), do: "0x" <> Base.encode16(binary, case: :lower)
  defp topic_address(binary), do: "0x" <> String.duplicate("00", 12) <> Base.encode16(binary, case: :lower)

  defp user_op(sender, call_data, paymaster_and_data \\ <<>>) do
    {sender, 0, <<>>, call_data, :binary.copy(<<0>>, 32), 0, :binary.copy(<<0>>, 32),
     paymaster_and_data, <<>>}
  end

  defp event_data(success, gas_cost) do
    ABI.TypeEncoder.encode([0, success, gas_cost, 99], [
      {:uint, 256},
      :bool,
      {:uint, 256},
      {:uint, 256}
    ])
  end

  defp bundle_block do
    smart_account_1 = addr(0xA1)
    smart_account_2 = addr(0xA2)
    token = addr(0x77)
    router = addr(0x88)
    paymaster = addr(0x9E)

    transfer = ABI.encode("transfer(address,uint256)", [addr(0x01), 5])
    approve = ABI.encode("approve(address,uint256)", [router, 100])

    calldata =
      ABI.encode(@handle_ops_v07, [
        [
          user_op(smart_account_1, ABI.encode("execute(address,uint256,bytes)", [token, 0, transfer]), paymaster),
          user_op(smart_account_2, ABI.encode("executeBatch(address[],bytes[])", [[token, router], [approve, transfer]]))
        ],
        addr(0xBB)
      ])

    block = %{
      "number" => "0xF4241",
      "hash" => "0xbundle_block",
      "parentHash" => "0xparent",
      "timestamp" => "0x5F5E100",
      "gasUsed" => "0x5208",
      "gasLimit" => "0x1C9C380",
      "baseFeePerGas" => "0x3B9ACA00",
      "transactions" => [
        %{
          "hash" => "0xbundle_tx",
          "from" => hex(addr(0xBB)),
          "to" => @entry_point,
          "value" => "0x0",
          "input" => hex(calldata),
          "gasPrice" => "0x3B9ACA00",
          "nonce" => "0x1",
          "type" => "0x2",
          "transactionIndex" => "0x0"
        }
      ]
    }

    receipts = [
      %{
        "transactionHash" => "0xbundle_tx",
        "status" => "0x1",
        "gasUsed" => "0x30D40",
        "logs" => [
          %{
            "logIndex" => "0x0",
            "address" => @entry_point,
            "topics" => [
              @user_op_event_topic0,
              "0x" <> String.duplicate("11", 32),
              topic_address(smart_account_1),
              topic_address(paymaster)
            ],
            "data" => hex(event_data(true, 12_345))
          },
          %{
            "logIndex" => "0x1",
            "address" => @entry_point,
            "topics" => [
              @user_op_event_topic0,
              "0x" <> String.duplicate("22", 32),
              topic_address(smart_account_2),
              topic_address(:binary.copy(<<0>>, 20))
            ],
            "data" => hex(event_data(false, 999))
          }
        ]
      }
    ]

    {block, receipts}
  end

  describe "process_block/3 with an ERC-4337 bundle" do
    setup do
      {block, receipts} = bundle_block()
      %{result: BlockProcessor.process_block(block, receipts, Rexplorer.Chain.Ethereum)}
    end

    test "produces one operation per inner call, attributed to the smart accounts", %{result: result} do
      assert length(result.operations) == 3

      assert Enum.all?(result.operations, &(&1.operation_type == :user_operation))
      assert Enum.map(result.operations, & &1.from_address) == [
               hex(addr(0xA1)),
               hex(addr(0xA2)),
               hex(addr(0xA2))
             ]

      assert Enum.map(result.operations, & &1.operation_index) == [0, 1, 2]
      assert Enum.map(result.operations, & &1.op_extra["user_op_index"]) == [0, 1, 1]
    end

    test "reaches the result with op_extra intact", %{result: result} do
      [first | _] = result.operations

      assert first.op_extra["user_op_hash"] == "0x" <> String.duplicate("11", 32)
      assert first.op_extra["paymaster"] == hex(addr(0x9E))
      assert first.op_extra["entry_point"] == @entry_point
      assert first.op_extra["entry_point_version"] == "0.7"
      assert first.op_extra["success"] == true
      assert first.op_extra["actual_gas_cost"] == "12345"
    end

    test "marks only the failed UserOperation unsuccessful", %{result: result} do
      [_first, second, third] = result.operations

      assert second.op_extra["success"] == false
      assert third.op_extra["success"] == false
      assert second.op_extra["user_op_hash"] == "0x" <> String.duplicate("22", 32)
    end

    test "points each operation at the real target", %{result: result} do
      assert Enum.map(result.operations, & &1.to_address) == [
               hex(addr(0x77)),
               hex(addr(0x77)),
               hex(addr(0x88))
             ]
    end

    test "still extracts the EntryPoint logs", %{result: result} do
      assert length(result.logs) == 2
      assert Enum.all?(result.logs, &(&1.contract_address == @entry_point))
      assert Enum.all?(result.logs, &(&1.topic0 == @user_op_event_topic0))
      assert Enum.all?(result.logs, &(&1.tx_hash == "0xbundle_tx"))
    end

    test "carries the chain id onto every operation", %{result: result} do
      assert Enum.all?(result.operations, &(&1.chain_id == 1))
      assert Enum.all?(result.operations, &(&1.tx_hash == "0xbundle_tx"))
    end
  end

  describe "a bundle inside a frame transaction" do
    test "unwraps using the frame's own logs" do
      smart_account = addr(0xA5)
      token = addr(0x77)
      transfer = ABI.encode("transfer(address,uint256)", [addr(0x01), 5])

      calldata =
        ABI.encode(@handle_ops_v07, [
          [user_op(smart_account, ABI.encode("execute(address,uint256,bytes)", [token, 0, transfer]))],
          addr(0xBB)
        ])

      frame_tx = %{
        "hash" => "0xframe_bundle_tx",
        "type" => "0x6",
        "sender" => hex(addr(0xBB)),
        "from" => hex(addr(0xBB)),
        "nonce" => "0x1",
        "maxFeePerGas" => "0x77359400",
        "transactionIndex" => "0x0",
        "frames" => [
          %{"mode" => "0x2", "to" => @entry_point, "gasLimit" => "0x7a120", "data" => hex(calldata)}
        ]
      }

      receipt = %{
        "transactionHash" => "0xframe_bundle_tx",
        "status" => "0x1",
        "gasUsed" => "0x33791",
        "payer" => hex(addr(0xBB)),
        "frameReceipts" => [
          %{
            "status" => "0x1",
            "gasUsed" => "0x2108e",
            "logs" => [
              %{
                "logIndex" => "0x0",
                "address" => @entry_point,
                "topics" => [
                  @user_op_event_topic0,
                  "0x" <> String.duplicate("33", 32),
                  topic_address(smart_account),
                  topic_address(:binary.copy(<<0>>, 20))
                ],
                "data" => hex(event_data(true, 42))
              }
            ]
          }
        ]
      }

      block = %{
        "number" => "0xF4242",
        "hash" => "0xframe_bundle_block",
        "parentHash" => "0xparent",
        "timestamp" => "0x5F5E100",
        "gasUsed" => "0x5208",
        "gasLimit" => "0x1C9C380",
        "baseFeePerGas" => "0x3B9ACA00",
        "transactions" => [frame_tx]
      }

      result = BlockProcessor.process_block(block, [receipt], Rexplorer.Chain.Ethereum)

      assert [operation] = result.operations
      assert operation.operation_type == :user_operation
      assert operation.from_address == hex(smart_account)
      assert operation.to_address == hex(token)
      assert operation.frame_index == 0
      assert operation.op_extra["user_op_hash"] == "0x" <> String.duplicate("33", 32)
    end
  end

  describe "address discovery for a bundle" do
    setup do
      {block, receipts} = bundle_block()
      %{result: BlockProcessor.process_block(block, receipts, Rexplorer.Chain.Ethereum)}
    end

    defp label_for(result, hash) do
      Enum.find_value(result.addresses, fn address ->
        if address.hash == hash, do: Map.get(address, :label)
      end)
    end

    test "labels the entry point with its version", %{result: result} do
      assert label_for(result, @entry_point) == "ERC-4337 EntryPoint v0.7"
    end

    test "labels the paymaster and both smart accounts", %{result: result} do
      assert label_for(result, hex(addr(0x9E))) == "ERC-4337 Paymaster"
      assert label_for(result, hex(addr(0xA1))) == "Smart Account"
      assert label_for(result, hex(addr(0xA2))) == "Smart Account"
    end

    test "discovers smart accounts that appear nowhere else in the block", %{result: result} do
      # The senders are not the tx from/to and emitted no logs of their own
      hashes = Enum.map(result.addresses, & &1.hash)

      assert hex(addr(0xA1)) in hashes
      assert hex(addr(0xA2)) in hashes
    end

    test "yields one entry per address even when it is both a participant and a role", %{
      result: result
    } do
      # The entry point is the transaction's to_address and a labelled role
      entries = Enum.filter(result.addresses, &(&1.hash == @entry_point))

      assert length(entries) == 1
      assert hd(entries).label == "ERC-4337 EntryPoint v0.7"
    end

    test "leaves the bundler unlabelled", %{result: result} do
      assert label_for(result, hex(addr(0xBB))) == nil
    end
  end
end
