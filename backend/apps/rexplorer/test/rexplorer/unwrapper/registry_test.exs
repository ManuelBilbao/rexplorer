defmodule Rexplorer.Unwrapper.RegistryTest do
  use ExUnit.Case, async: true

  alias Rexplorer.Unwrapper.Registry

  @handle_ops_v06 "handleOps((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)"
  @user_op_event_topic0 "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"

  defp addr(byte), do: :binary.copy(<<byte>>, 20)
  defp hex(binary), do: "0x" <> Base.encode16(binary, case: :lower)

  defp transaction(input, extra \\ %{}) do
    Map.merge(
      %{
        from_address: hex(addr(0xBB)),
        to_address: hex(addr(0xEE)),
        value: Decimal.new(0),
        input: input
      },
      extra
    )
  end

  defp bundle_calldata(user_ops), do: ABI.encode(@handle_ops_v06, [user_ops, addr(0xBB)])

  defp user_op(sender, call_data),
    do: {sender, 0, <<>>, call_data, 0, 0, 0, 0, 0, <<>>, <<>>}

  defp user_op_event(hash) do
    %{
      topic0: @user_op_event_topic0,
      topic1: hash,
      topic2: "0x" <> String.duplicate("00", 12) <> Base.encode16(addr(0xA1), case: :lower),
      topic3: "0x" <> String.duplicate("00", 32),
      data:
        ABI.TypeEncoder.encode([0, true, 500, 99], [
          {:uint, 256},
          :bool,
          {:uint, 256},
          {:uint, 256}
        ]),
      contract_address: hex(addr(0xEE))
    }
  end

  describe "routing" do
    test "a bundle routes to the ERC-4337 unwrapper" do
      input = bundle_calldata([user_op(addr(0xA1), <<>>), user_op(addr(0xA2), <<>>)])

      operations = Registry.unwrap(transaction(input), 1)

      assert length(operations) == 2
      assert Enum.all?(operations, &(&1.operation_type == :user_operation))
      assert Enum.map(operations, & &1.from_address) == [hex(addr(0xA1)), hex(addr(0xA2))]
    end

    test "a bundle with logs picks up the event fields" do
      hash = "0x" <> String.duplicate("ab", 32)
      input = bundle_calldata([user_op(addr(0xA1), <<>>)])

      [operation] = Registry.unwrap(transaction(input, %{logs: [user_op_event(hash)]}), 1)

      assert operation.op_extra["user_op_hash"] == hash
      assert operation.op_extra["success"] == true
    end

    test "the same bundle without logs still unwraps" do
      input = bundle_calldata([user_op(addr(0xA1), <<>>)])

      [operation] = Registry.unwrap(transaction(input), 1)

      assert operation.operation_type == :user_operation
      refute Map.has_key?(operation.op_extra, "user_op_hash")
    end

    test "a Safe transaction still routes to the Safe unwrapper" do
      inner = ABI.encode("transfer(address,uint256)", [addr(0x01), 5])

      input =
        ABI.encode(
          "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)",
          [addr(0x77), 0, inner, 0, 0, 0, 0, addr(0x00), addr(0x00), <<>>]
        )

      assert [operation] = Registry.unwrap(transaction(input), 1)
      assert operation.operation_type == :multisig_execution
    end

    test "a multicall still routes to the Multicall unwrapper" do
      input = ABI.encode("multicall(bytes[])", [[<<0x01>>, <<0x02>>]])

      operations = Registry.unwrap(transaction(input), 1)

      assert length(operations) == 2
      assert Enum.all?(operations, &(&1.operation_type == :multicall_item))
    end

    test "a plain transaction falls through to a single call" do
      input = ABI.encode("transfer(address,uint256)", [addr(0x01), 5])

      assert [operation] = Registry.unwrap(transaction(input), 1)
      assert operation.operation_type == :call
      assert operation.operation_index == 0
    end
  end

  describe "fallback" do
    test "an undecodable bundle falls back to a single call" do
      input = <<0x1F, 0xAD, 0x94, 0x8C>> <> :binary.copy(<<0xAB>>, 32)

      assert [operation] = Registry.unwrap(transaction(input), 1)
      assert operation.operation_type == :call
      assert operation.input == input
    end

    test "an undecodable Safe transaction falls back to a single call" do
      input = <<0x6A, 0x76, 0x12, 0x02>> <> :binary.copy(<<0xAB>>, 32)

      assert [operation] = Registry.unwrap(transaction(input), 1)
      assert operation.operation_type == :call
    end

    test "an empty bundle falls back to a single call" do
      input = bundle_calldata([])

      assert [operation] = Registry.unwrap(transaction(input), 1)
      assert operation.operation_type == :call
    end
  end
end
