defmodule RexplorerWeb.UserOperationsTest do
  use RexplorerWeb.ConnCase, async: true

  alias Rexplorer.{Repo, Schema.Block, Schema.Chain, Schema.Operation, Schema.Transaction}

  @chain_id 99995
  @slug "uo-test"
  @bundle_tx "0x" <> String.duplicate("11", 32)
  @plain_tx "0x" <> String.duplicate("22", 32)
  @user_op_hash "0x" <> String.duplicate("ab", 32)
  @entry_point "0x0000000071727de22e5e9d8baf0edac6f37da032"
  @paymaster "0x9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e"
  @smart_account "0xa1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1"

  setup %{conn: conn} do
    unless Repo.get(Chain, @chain_id) do
      %Chain{}
      |> Chain.changeset(%{
        chain_id: @chain_id,
        name: "UserOp Test Chain",
        chain_type: :l1,
        native_token_symbol: "ETH",
        explorer_slug: @slug
      })
      |> Repo.insert!()
    end

    block =
      %Block{}
      |> Block.changeset(%{
        chain_id: @chain_id,
        block_number: 500,
        hash: "0xuo_block",
        parent_hash: "0xuo_parent",
        timestamp: ~U[2026-01-01 00:00:00Z],
        gas_used: 21_000,
        gas_limit: 30_000_000
      })
      |> Repo.insert!()

    bundle = insert_tx(block, @bundle_tx, @entry_point)
    plain = insert_tx(block, @plain_tx, "0xtoken", 1)

    # Two UserOperations; the second batched two calls and failed
    insert_operation(bundle, 0, %{
      "user_op_hash" => @user_op_hash,
      "user_op_index" => 0,
      "entry_point" => @entry_point,
      "entry_point_version" => "0.7",
      "paymaster" => @paymaster,
      "success" => true,
      "actual_gas_cost" => "12345"
    })

    for index <- [1, 2] do
      insert_operation(bundle, index, %{
        "user_op_hash" => "0x" <> String.duplicate("cd", 32),
        "user_op_index" => 1,
        "entry_point" => @entry_point,
        "entry_point_version" => "0.7",
        "success" => false
      })
    end

    insert_operation(plain, 0, %{}, :call)

    %{conn: conn}
  end

  defp insert_tx(block, hash, to_address, index \\ 0) do
    %Transaction{}
    |> Transaction.changeset(%{
      chain_id: @chain_id,
      block_id: block.id,
      hash: hash,
      from_address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      to_address: to_address,
      nonce: index,
      transaction_index: index,
      status: true
    })
    |> Repo.insert!()
  end

  defp insert_operation(tx, index, op_extra, type \\ :user_operation) do
    %Operation{}
    |> Operation.changeset(%{
      transaction_id: tx.id,
      chain_id: @chain_id,
      operation_type: type,
      operation_index: index,
      from_address: @smart_account,
      to_address: "0x7777777777777777777777777777777777777777",
      decoded_summary: "Smart account #{@smart_account} transferred 5 USDC",
      op_extra: op_extra
    })
    |> Repo.insert!()
  end

  describe "BFF transaction detail" do
    test "returns the ERC-4337 fields per operation", %{conn: conn} do
      conn = get(conn, "/internal/chains/#{@slug}/transactions/#{@bundle_tx}")

      assert %{"operations" => operations} = json_response(conn, 200)
      assert length(operations) == 3

      first = hd(operations)
      assert first["op_extra"]["user_op_hash"] == @user_op_hash
      assert first["op_extra"]["user_op_index"] == 0
      assert first["op_extra"]["entry_point"] == @entry_point
      assert first["op_extra"]["entry_point_version"] == "0.7"
      assert first["op_extra"]["paymaster"] == @paymaster
      assert first["op_extra"]["success"] == true
      assert first["op_extra"]["actual_gas_cost"] == "12345"
    end

    test "lets the client group a batched UserOperation without a second request", %{conn: conn} do
      conn = get(conn, "/internal/chains/#{@slug}/transactions/#{@bundle_tx}")

      %{"operations" => operations} = json_response(conn, 200)

      grouped = Enum.group_by(operations, & &1["op_extra"]["user_op_index"])

      assert map_size(grouped) == 2
      assert length(grouped[1]) == 2
      assert Enum.all?(grouped[1], &(&1["op_extra"]["success"] == false))
    end

    test "a non-AA transaction carries an empty op_extra and is otherwise unchanged", %{
      conn: conn
    } do
      conn = get(conn, "/internal/chains/#{@slug}/transactions/#{@plain_tx}")

      assert %{"operations" => [operation]} = json_response(conn, 200)
      assert operation["op_extra"] == %{}
      assert operation["operation_type"] == "call"
      assert operation["from_address"] == @smart_account
      assert operation["frame_index"] == nil
    end
  end

  describe "public operations endpoint" do
    test "returns the ERC-4337 fields", %{conn: conn} do
      conn = get(conn, "/api/v1/chains/#{@slug}/transactions/#{@bundle_tx}/operations")

      assert %{"data" => [first | _]} = json_response(conn, 200)
      assert first["operation_type"] == "user_operation"
      assert first["op_extra"]["user_op_hash"] == @user_op_hash
      assert first["op_extra"]["paymaster"] == @paymaster
    end

    test "a plain call keeps its previous shape plus an empty op_extra", %{conn: conn} do
      conn = get(conn, "/api/v1/chains/#{@slug}/transactions/#{@plain_tx}/operations")

      assert %{"data" => [operation]} = json_response(conn, 200)

      assert Map.keys(operation) |> Enum.sort() == [
               "decoded_summary",
               "from_address",
               "op_extra",
               "operation_index",
               "operation_type",
               "to_address",
               "value"
             ]

      assert operation["op_extra"] == %{}
    end
  end

  describe "search" do
    test "a userOpHash resolves to its transaction", %{conn: conn} do
      conn = get(conn, "/internal/search?q=#{@user_op_hash}")

      assert %{"type" => "user_operation", "results" => [result], "redirect" => redirect} =
               json_response(conn, 200)

      assert result["transaction_hash"] == @bundle_tx
      assert result["user_op_hash"] == @user_op_hash
      assert result["chain"] == @slug
      assert result["block_number"] == 500
      assert redirect == "/#{@slug}/tx/#{@bundle_tx}"
    end

    test "a transaction hash still resolves as a transaction", %{conn: conn} do
      conn = get(conn, "/internal/search?q=#{@bundle_tx}")

      assert %{"type" => "transaction", "results" => [result]} = json_response(conn, 200)
      assert result["hash"] == @bundle_tx
      assert result["chain"] == @slug
    end

    test "an unknown hash returns no results", %{conn: conn} do
      conn = get(conn, "/internal/search?q=0x#{String.duplicate("ee", 32)}")

      assert %{"results" => []} = json_response(conn, 200)
    end
  end

  describe "OpenAPI document" do
    test "describes the ERC-4337 operation fields as optional", %{conn: conn} do
      conn = get(conn, "/api/openapi")

      spec = json_response(conn, 200)
      operation = spec["components"]["schemas"]["Operation"]
      op_extra = operation["properties"]["op_extra"]

      assert op_extra["type"] == "object"

      assert Map.keys(op_extra["properties"]) |> Enum.sort() == [
               "actual_gas_cost",
               "entry_point",
               "entry_point_version",
               "factory",
               "paymaster",
               "success",
               "user_op_hash",
               "user_op_index"
             ]

      # Optional: nothing in op_extra is required
      refute Map.has_key?(op_extra, "required")
    end
  end
end
