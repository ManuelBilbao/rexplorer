defmodule Rexplorer.LabelsTest do
  use ExUnit.Case, async: true

  alias Rexplorer.Labels

  defp user_operation(from, extra) do
    %{operation_type: :user_operation, from_address: from, op_extra: extra}
  end

  describe "from_operations/1" do
    test "labels the entry point with its version, the paymaster and the smart account" do
      operations = [
        user_operation("0xacc1", %{
          "entry_point" => "0xep",
          "entry_point_version" => "0.7",
          "paymaster" => "0xpm"
        })
      ]

      assert Labels.from_operations(operations) == %{
               "0xep" => "ERC-4337 EntryPoint v0.7",
               "0xpm" => "ERC-4337 Paymaster",
               "0xacc1" => "Smart Account"
             }
    end

    test "labels the factory of a deploying UserOperation" do
      operations = [
        user_operation("0xacc1", %{
          "entry_point" => "0xep",
          "entry_point_version" => "0.6",
          "factory" => "0xfactory"
        })
      ]

      labels = Labels.from_operations(operations)

      assert labels["0xfactory"] == "ERC-4337 Account Factory"
      assert labels["0xep"] == "ERC-4337 EntryPoint v0.6"
    end

    test "omits roles the bundle did not have" do
      operations = [user_operation("0xacc1", %{"entry_point" => "0xep"})]

      labels = Labels.from_operations(operations)

      refute Enum.any?(Map.values(labels), &(&1 == "ERC-4337 Paymaster"))
      refute Enum.any?(Map.values(labels), &(&1 == "ERC-4337 Account Factory"))
      assert labels["0xep"] == "ERC-4337 EntryPoint"
    end

    test "resolves an address holding two roles by priority" do
      # A paymaster that is also a smart account in the same block
      operations = [
        user_operation("0xboth", %{"entry_point" => "0xep", "paymaster" => "0xboth"})
      ]

      assert Labels.from_operations(operations)["0xboth"] == "ERC-4337 Paymaster"
    end

    test "is order-independent, so re-indexing yields the same labels" do
      operations = [
        user_operation("0xboth", %{"entry_point" => "0xep", "paymaster" => "0xpm"}),
        user_operation("0xpm", %{"entry_point" => "0xep"})
      ]

      assert Labels.from_operations(operations) ==
               Labels.from_operations(Enum.reverse(operations))
    end

    test "several UserOperations produce one label per address" do
      operations = [
        user_operation("0xacc1", %{"entry_point" => "0xep", "entry_point_version" => "0.7"}),
        user_operation("0xacc2", %{"entry_point" => "0xep", "entry_point_version" => "0.7"}),
        user_operation("0xacc2", %{"entry_point" => "0xep", "entry_point_version" => "0.7"})
      ]

      labels = Labels.from_operations(operations)

      assert map_size(labels) == 3
      assert labels["0xacc2"] == "Smart Account"
    end

    test "ignores operations that are not user operations" do
      operations = [
        %{operation_type: :call, from_address: "0xeoa", op_extra: %{}},
        %{operation_type: :multicall_item, from_address: "0xeoa2", op_extra: %{}}
      ]

      assert Labels.from_operations(operations) == %{}
    end

    test "tolerates operations with no op_extra" do
      assert Labels.from_operations([%{operation_type: :user_operation, from_address: "0xacc"}]) ==
               %{"0xacc" => "Smart Account"}
    end

    test "returns an empty map for anything else" do
      assert Labels.from_operations([]) == %{}
      assert Labels.from_operations(nil) == %{}
    end
  end
end
