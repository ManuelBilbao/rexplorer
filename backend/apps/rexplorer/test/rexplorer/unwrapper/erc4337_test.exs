defmodule Rexplorer.Unwrapper.ERC4337Test do
  use ExUnit.Case, async: true

  alias Rexplorer.Unwrapper.ERC4337

  @handle_ops_v06 "handleOps((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)"
  @handle_ops_v07 "handleOps((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[],address)"
  @user_op_event_topic0 "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"

  @entry_point_v07 "0x0000000071727de22e5e9d8baf0edac6f37da032"
  @bundler "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  # ── Fixture helpers ──────────────────────────────────────────────────

  defp addr(byte), do: :binary.copy(<<byte>>, 20)
  defp hex(binary), do: "0x" <> Base.encode16(binary, case: :lower)

  defp user_op_v06(sender, call_data, opts \\ []) do
    {sender, Keyword.get(opts, :nonce, 0), Keyword.get(opts, :init_code, <<>>), call_data, 0, 0,
     0, 0, 0, Keyword.get(opts, :paymaster_and_data, <<>>), <<>>}
  end

  defp user_op_v07(sender, call_data, opts \\ []) do
    {sender, Keyword.get(opts, :nonce, 0), Keyword.get(opts, :init_code, <<>>), call_data,
     :binary.copy(<<0>>, 32), 0, :binary.copy(<<0>>, 32),
     Keyword.get(opts, :paymaster_and_data, <<>>), <<>>}
  end

  defp bundle(signature, user_ops), do: ABI.encode(signature, [user_ops, addr(0xBB)])

  defp transaction(input, opts \\ []) do
    %{
      from_address: @bundler,
      to_address: Keyword.get(opts, :to, @entry_point_v07),
      value: Decimal.new(0),
      input: input
    }
    |> then(fn tx ->
      case Keyword.get(opts, :logs) do
        nil -> tx
        logs -> Map.put(tx, :logs, logs)
      end
    end)
  end

  defp user_op_event(opts) do
    %{
      topic0: @user_op_event_topic0,
      topic1: Keyword.get(opts, :hash, "0x" <> String.duplicate("ab", 32)),
      topic2: topic_address(Keyword.get(opts, :sender, addr(0xAC))),
      topic3: topic_address(Keyword.get(opts, :paymaster, :binary.copy(<<0>>, 20))),
      data:
        ABI.TypeEncoder.encode(
          [0, Keyword.get(opts, :success, true), Keyword.get(opts, :gas_cost, 12_345), 99],
          [{:uint, 256}, :bool, {:uint, 256}, {:uint, 256}]
        ),
      contract_address: @entry_point_v07
    }
  end

  defp topic_address(binary),
    do: "0x" <> String.duplicate("00", 12) <> Base.encode16(binary, case: :lower)

  defp execute(dest, value, func),
    do: ABI.encode("execute(address,uint256,bytes)", [dest, value, func])

  defp execute_batch(dests, funcs),
    do: ABI.encode("executeBatch(address[],bytes[])", [dests, funcs])

  defp execute_batch(dests, values, funcs),
    do: ABI.encode("executeBatch(address[],uint256[],bytes[])", [dests, values, funcs])

  defp transfer_calldata(to, amount),
    do: ABI.encode("transfer(address,uint256)", [to, amount])

  # ── Detection ────────────────────────────────────────────────────────

  describe "matches?/2" do
    test "matches a v0.6 bundle" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xAC), <<>>)])
      assert ERC4337.matches?(%{input: input}, 1)
    end

    test "matches a v0.7 bundle" do
      input = bundle(@handle_ops_v07, [user_op_v07(addr(0xAC), <<>>)])
      assert ERC4337.matches?(%{input: input}, 1)
    end

    test "does not match handleAggregatedOps" do
      # 0x4b1d7cf5 — aggregated bundles have a different calldata shape
      refute ERC4337.matches?(%{input: <<0x4B, 0x1D, 0x7C, 0xF5, 0x00>>}, 1)
    end

    test "does not match a Safe execTransaction" do
      refute ERC4337.matches?(%{input: <<0x6A, 0x76, 0x12, 0x02, 0x00>>}, 1)
    end

    test "does not match a plain transfer or an empty input" do
      refute ERC4337.matches?(%{input: transfer_calldata(addr(0x01), 1)}, 1)
      refute ERC4337.matches?(%{input: nil}, 1)
      refute ERC4337.matches?(%{input: <<>>}, 1)
    end
  end

  # ── Bundle decoding ──────────────────────────────────────────────────

  describe "sender attribution" do
    test "attributes each operation to its own smart account, not the bundler" do
      token = addr(0x77)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute(token, 0, transfer_calldata(addr(0x01), 5))),
          user_op_v06(addr(0xA2), execute(token, 0, transfer_calldata(addr(0x02), 7))),
          user_op_v06(addr(0xA3), execute(token, 0, transfer_calldata(addr(0x03), 9)))
        ])

      operations = ERC4337.unwrap(transaction(input), 1)

      assert length(operations) == 3

      assert Enum.map(operations, & &1.from_address) == [
               hex(addr(0xA1)),
               hex(addr(0xA2)),
               hex(addr(0xA3))
             ]

      refute Enum.any?(operations, &(&1.from_address == @bundler))
      assert Enum.all?(operations, &(&1.operation_type == :user_operation))
    end

    test "records the entry point and version for a v0.6 bundle" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      [operation] =
        ERC4337.unwrap(transaction(input, to: "0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789"), 1)

      assert operation.op_extra["entry_point_version"] == "0.6"
      assert operation.op_extra["entry_point"] == "0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789"
    end

    test "records the entry point version for a v0.7 bundle" do
      input = bundle(@handle_ops_v07, [user_op_v07(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.op_extra["entry_point_version"] == "0.7"
      assert operation.op_extra["entry_point"] == @entry_point_v07
    end

    test "names v0.8 by its address, since it shares v0.7's calldata shape" do
      input = bundle(@handle_ops_v07, [user_op_v07(addr(0xA1), <<>>)])
      v08 = "0x4337084d9e255ff0702461cf8895ce9e3b5ff108"

      [operation] = ERC4337.unwrap(transaction(input, to: v08), 1)

      assert operation.op_extra["entry_point_version"] == "0.8"
    end

    test "falls back to the calldata shape for a non-canonical entry point" do
      input = bundle(@handle_ops_v07, [user_op_v07(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input, to: hex(addr(0xEE))), 1)

      assert operation.op_extra["entry_point_version"] == "0.7"
    end
  end

  describe "paymaster and factory extraction" do
    test "reads the paymaster from paymasterAndData when there are no logs" do
      paymaster = addr(0x9E)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), <<>>, paymaster_and_data: paymaster <> <<1, 2, 3>>)
        ])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.op_extra["paymaster"] == hex(paymaster)
    end

    test "omits the paymaster for a self-funded UserOperation" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      refute Map.has_key?(operation.op_extra, "paymaster")
    end

    test "records the factory from initCode" do
      factory = addr(0xFA)

      input =
        bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>, init_code: factory <> <<9, 9>>)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.op_extra["factory"] == hex(factory)
    end

    test "omits the factory when the account already exists" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      refute Map.has_key?(operation.op_extra, "factory")
    end
  end

  describe "fallback" do
    test "returns no operations for undecodable calldata" do
      assert ERC4337.unwrap(transaction(<<0x1F, 0xAD, 0x94, 0x8C, 0xFF, 0xFF>>), 1) == []
    end

    test "returns no operations for an empty bundle" do
      input = bundle(@handle_ops_v06, [])
      assert ERC4337.unwrap(transaction(input), 1) == []
    end

    test "returns no operations for garbage after the selector" do
      input = <<0x76, 0x5E, 0x82, 0x7F>> <> :binary.copy(<<0xAB>>, 64)
      assert ERC4337.unwrap(transaction(input), 1) == []
    end
  end

  # ── Account call fan-out ─────────────────────────────────────────────

  describe "execute" do
    test "points the operation at the inner target with the inner calldata" do
      token = addr(0x77)
      inner = transfer_calldata(addr(0x01), 5)
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), execute(token, 42, inner))])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.from_address == hex(addr(0xA1))
      assert operation.to_address == hex(token)
      assert operation.value == Decimal.new(42)
      assert operation.input == inner
    end
  end

  describe "executeBatch" do
    test "fans out to one operation per inner call" do
      token = addr(0x77)
      router = addr(0x88)
      approve = ABI.encode("approve(address,uint256)", [router, 100])
      swap = transfer_calldata(addr(0x02), 3)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute_batch([token, router], [approve, swap]))
        ])

      operations = ERC4337.unwrap(transaction(input), 1)

      assert length(operations) == 2
      assert Enum.map(operations, & &1.to_address) == [hex(token), hex(router)]
      assert Enum.map(operations, & &1.input) == [approve, swap]
      assert Enum.all?(operations, &(&1.value == Decimal.new(0)))
      assert Enum.all?(operations, &(&1.from_address == hex(addr(0xA1))))
    end

    test "carries per-call values in the three-argument shape" do
      a = addr(0x77)
      b = addr(0x88)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute_batch([a, b], [10, 20], [<<0x01>>, <<0x02>>]))
        ])

      operations = ERC4337.unwrap(transaction(input), 1)

      assert Enum.map(operations, & &1.value) == [Decimal.new(10), Decimal.new(20)]
    end

    test "all operations from one UserOperation share its user_op_index" do
      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute(addr(0x77), 0, <<0x01>>)),
          user_op_v06(addr(0xA2), execute_batch([addr(0x77), addr(0x88)], [<<0x02>>, <<0x03>>]))
        ])

      operations = ERC4337.unwrap(transaction(input), 1)

      assert Enum.map(operations, & &1.operation_index) == [0, 1, 2]
      assert Enum.map(operations, & &1.op_extra["user_op_index"]) == [0, 1, 1]
    end
  end

  describe "unrecognized account interfaces" do
    test "keeps the operation at the smart account with the raw calldata" do
      # A wallet-specific execution selector the lookup table does not know
      unknown = <<0xDE, 0xAD, 0xBE, 0xEF>> <> :binary.copy(<<0>>, 32)
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), unknown)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.to_address == hex(addr(0xA1))
      assert operation.input == unknown
    end

    test "produces an operation with no input for empty callData" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.to_address == hex(addr(0xA1))
      assert operation.input == nil
    end
  end

  # ── Event correlation ────────────────────────────────────────────────

  describe "UserOperationEvent correlation" do
    test "stamps each operation with its own hash, paymaster and gas cost" do
      hashes = for i <- 1..3, do: "0x" <> String.duplicate(Integer.to_string(i) <> "0", 32)
      paymaster = addr(0x9E)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute(addr(0x77), 0, <<0x01>>)),
          user_op_v06(addr(0xA2), execute(addr(0x77), 0, <<0x02>>)),
          user_op_v06(addr(0xA3), execute(addr(0x77), 0, <<0x03>>))
        ])

      logs =
        [
          user_op_event(hash: Enum.at(hashes, 0), sender: addr(0xA1), paymaster: paymaster),
          user_op_event(hash: Enum.at(hashes, 1), sender: addr(0xA2)),
          user_op_event(hash: Enum.at(hashes, 2), sender: addr(0xA3), gas_cost: 777)
        ]

      operations = ERC4337.unwrap(transaction(input, logs: logs), 1)

      assert Enum.map(operations, & &1.op_extra["user_op_hash"]) == hashes
      assert Enum.at(operations, 0).op_extra["paymaster"] == hex(paymaster)
      assert Enum.at(operations, 2).op_extra["actual_gas_cost"] == "777"
      assert Enum.all?(operations, & &1.op_extra["success"])
    end

    test "a batched UserOperation's operations share one hash" do
      hash = "0x" <> String.duplicate("cd", 32)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute_batch([addr(0x77), addr(0x88)], [<<0x01>>, <<0x02>>]))
        ])

      operations = ERC4337.unwrap(transaction(input, logs: [user_op_event(hash: hash)]), 1)

      assert length(operations) == 2
      assert Enum.all?(operations, &(&1.op_extra["user_op_hash"] == hash))
    end

    test "the event's paymaster wins over the calldata prefix" do
      calldata_paymaster = addr(0x11)
      event_paymaster = addr(0x22)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), <<>>, paymaster_and_data: calldata_paymaster <> <<7>>)
        ])

      logs = [user_op_event(paymaster: event_paymaster)]

      [operation] = ERC4337.unwrap(transaction(input, logs: logs), 1)

      assert operation.op_extra["paymaster"] == hex(event_paymaster)
    end

    test "a zero paymaster in the event means self-funded" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      [operation] = ERC4337.unwrap(transaction(input, logs: [user_op_event([])]), 1)

      refute Map.has_key?(operation.op_extra, "paymaster")
    end

    test "marks only the failed UserOperation unsuccessful" do
      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), execute(addr(0x77), 0, <<0x01>>)),
          user_op_v06(addr(0xA2), execute(addr(0x77), 0, <<0x02>>))
        ])

      logs = [
        user_op_event(sender: addr(0xA1), success: true),
        user_op_event(sender: addr(0xA2), success: false)
      ]

      [first, second] = ERC4337.unwrap(transaction(input, logs: logs), 1)

      assert first.op_extra["success"] == true
      assert second.op_extra["success"] == false
    end

    test "skips correlation when the event count does not match" do
      calldata_paymaster = addr(0x11)

      input =
        bundle(@handle_ops_v06, [
          user_op_v06(addr(0xA1), <<>>, paymaster_and_data: calldata_paymaster <> <<7>>),
          user_op_v06(addr(0xA2), <<>>)
        ])

      # One event for two UserOperations — a positional zip would misattribute
      logs = [user_op_event(hash: "0x" <> String.duplicate("ee", 32))]

      operations = ERC4337.unwrap(transaction(input, logs: logs), 1)

      assert length(operations) == 2
      refute Enum.any?(operations, &Map.has_key?(&1.op_extra, "user_op_hash"))
      refute Enum.any?(operations, &Map.has_key?(&1.op_extra, "success"))
      # Calldata-derived extras survive
      assert Enum.at(operations, 0).op_extra["paymaster"] == hex(calldata_paymaster)
    end

    test "ignores unrelated logs in the same transaction" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), <<>>)])

      transfer_log = %{
        topic0: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
        topic1: topic_address(addr(0x01)),
        topic2: topic_address(addr(0x02)),
        topic3: nil,
        data: <<>>,
        contract_address: hex(addr(0x77))
      }

      hash = "0x" <> String.duplicate("fa", 32)
      logs = [transfer_log, user_op_event(hash: hash)]

      [operation] = ERC4337.unwrap(transaction(input, logs: logs), 1)

      assert operation.op_extra["user_op_hash"] == hash
    end

    test "produces operations without event fields when there are no logs" do
      input = bundle(@handle_ops_v06, [user_op_v06(addr(0xA1), execute(addr(0x77), 0, <<0x01>>))])

      [operation] = ERC4337.unwrap(transaction(input), 1)

      assert operation.to_address == hex(addr(0x77))
      refute Map.has_key?(operation.op_extra, "user_op_hash")
      refute Map.has_key?(operation.op_extra, "success")
      refute Map.has_key?(operation.op_extra, "actual_gas_cost")
    end
  end
end
