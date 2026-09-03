defmodule Rexplorer.Decoder.ABITest do
  use ExUnit.Case, async: true

  alias Rexplorer.Decoder.ABI, as: ABIRegistry
  alias Rexplorer.Decoder.EventDecoder

  @handle_ops_v06 "handleOps((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)"
  @handle_ops_v07 "handleOps((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[],address)"
  @user_operation_event "UserOperationEvent(bytes32,address,address,uint256,bool,uint256,uint256)"

  defp selector_hex(signature) do
    signature
    |> ABI.FunctionSelector.decode()
    |> ABI.FunctionSelector.encode()
    |> ExKeccak.hash_256()
    |> binary_part(0, 4)
    |> then(&("0x" <> Base.encode16(&1, case: :lower)))
  end

  defp selector_bytes(signature) do
    signature
    |> ABI.FunctionSelector.decode()
    |> ABI.FunctionSelector.encode()
    |> ExKeccak.hash_256()
    |> binary_part(0, 4)
  end

  describe "ERC-4337 selectors" do
    test "match the constants documented in the design" do
      assert selector_hex(@handle_ops_v06) == "0x1fad948c"
      assert selector_hex(@handle_ops_v07) == "0x765e827f"
      assert selector_hex("execute(address,uint256,bytes)") == "0xb61d27f6"
      assert selector_hex("executeBatch(address[],bytes[])") == "0x18dfb3c7"
      assert selector_hex("executeBatch(address[],uint256[],bytes[])") == "0x47e1da2a"
    end

    test "UserOperationEvent topic0 matches the EntryPoint's" do
      topic0 =
        @user_operation_event
        |> ExKeccak.hash_256()
        |> Base.encode16(case: :lower)

      assert "0x" <> topic0 ==
               "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"
    end
  end

  describe "handleOps registration" do
    test "both EntryPoint shapes are registered as distinct entries" do
      v06 = ABIRegistry.lookup_selector(selector_bytes(@handle_ops_v06))
      v07 = ABIRegistry.lookup_selector(selector_bytes(@handle_ops_v07))

      assert v06.function == "handleOps"
      assert v07.function == "handleOps"
      assert v06.param_names == ["ops", "beneficiary"]
      assert v07.param_names == ["ops", "beneficiary"]

      # Distinguishable by the ops tuple arity: 11 fields unpacked, 9 packed
      assert [{:array, {:tuple, v06_fields}}, :address] = v06.selector.types
      assert [{:array, {:tuple, v07_fields}}, :address] = v07.selector.types
      assert length(v06_fields) == 11
      assert length(v07_fields) == 9
    end
  end

  describe "account execution decoding" do
    test "execute decodes into dest, value and func" do
      dest = <<0x11>> |> :binary.copy(20)
      calldata = ABI.encode("execute(address,uint256,bytes)", [dest, 1_000, <<0xDE, 0xAD>>])

      assert {:ok, %{function: "execute", params: params}} = ABIRegistry.decode(calldata)
      assert params["dest"] == "0x" <> Base.encode16(dest, case: :lower)
      assert params["value"] == 1_000
      assert params["func"] == <<0xDE, 0xAD>>
    end

    test "executeBatch(address[],bytes[]) decodes into dest and func" do
      a = :binary.copy(<<0x22>>, 20)
      b = :binary.copy(<<0x33>>, 20)

      calldata =
        ABI.encode("executeBatch(address[],bytes[])", [[a, b], [<<0x01>>, <<0x02>>]])

      assert {:ok, %{function: "executeBatch", params: params}} = ABIRegistry.decode(calldata)

      assert params["dest"] == [
               "0x" <> Base.encode16(a, case: :lower),
               "0x" <> Base.encode16(b, case: :lower)
             ]

      assert params["func"] == [<<0x01>>, <<0x02>>]
      refute Map.has_key?(params, "value")
    end

    test "executeBatch(address[],uint256[],bytes[]) decodes into dest, value and func" do
      a = :binary.copy(<<0x44>>, 20)

      calldata =
        ABI.encode("executeBatch(address[],uint256[],bytes[])", [[a], [7], [<<0x05>>]])

      assert {:ok, %{function: "executeBatch", params: params}} = ABIRegistry.decode(calldata)
      assert params["dest"] == ["0x" <> Base.encode16(a, case: :lower)]
      assert params["value"] == [7]
      assert params["func"] == [<<0x05>>]
    end
  end

  describe "UserOperationEvent" do
    test "is registered and separates indexed from data parameters" do
      topic0 = "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"
      entry = ABIRegistry.lookup_event(topic0)

      assert entry.event_name == "UserOperationEvent"
      assert entry.indexed == [true, true, true, false, false, false, false]

      assert entry.param_names == [
               "userOpHash",
               "sender",
               "paymaster",
               "nonce",
               "success",
               "actualGasCost",
               "actualGasUsed"
             ]
    end

    test "decodes a log into hash, sender, paymaster, success and gas cost" do
      data =
        ABI.TypeEncoder.encode(
          [3, true, 12_345, 99],
          [{:uint, 256}, :bool, {:uint, 256}, {:uint, 256}]
        )

      log = %{
        topic0: "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f",
        topic1: "0x" <> String.duplicate("ab", 32),
        topic2: "0x" <> String.duplicate("00", 12) <> String.duplicate("11", 20),
        topic3: "0x" <> String.duplicate("00", 12) <> String.duplicate("22", 20),
        data: data,
        contract_address: "0x0000000071727de22e5e9d8baf0edac6f37da032"
      }

      decoded = EventDecoder.decode_log(log)

      assert decoded.event_name == "UserOperationEvent"
      assert decoded.params["userOpHash"] == "0x" <> String.duplicate("ab", 32)
      assert decoded.params["sender"] == "0x" <> String.duplicate("11", 20)
      assert decoded.params["paymaster"] == "0x" <> String.duplicate("22", 20)
      assert decoded.params["success"] == "true"
      assert decoded.params["actualGasCost"] == "12345"
    end
  end
end
