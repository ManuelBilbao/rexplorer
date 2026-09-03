defmodule Rexplorer.Schema.OperationTest do
  use Rexplorer.DataCase, async: true

  alias Rexplorer.Schema.{Block, Chain, Operation, Transaction}

  setup do
    chain =
      case Repo.get(Chain, 99991) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: 99991,
            name: "Test Chain Ops",
            chain_type: :l1,
            native_token_symbol: "ETH",
            explorer_slug: "test-operation"
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    block =
      %Block{}
      |> Block.changeset(%{
        chain_id: chain.chain_id,
        block_number: 1,
        hash: "0xblock",
        parent_hash: "0xparent",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
        gas_used: 0,
        gas_limit: 30_000_000
      })
      |> Repo.insert!()

    tx =
      %Transaction{}
      |> Transaction.changeset(%{
        chain_id: chain.chain_id,
        block_id: block.id,
        hash: "0xtx",
        from_address: "0xbundler",
        to_address: "0xentrypoint",
        nonce: 0,
        transaction_index: 0
      })
      |> Repo.insert!()

    %{chain: chain, tx: tx}
  end

  test "op_extra round-trips through insert and reload", %{chain: chain, tx: tx} do
    extra = %{
      "user_op_hash" => "0xdeadbeef",
      "user_op_index" => 1,
      "entry_point" => "0x0000000071727de22e5e9d8baf0edac6f37da032",
      "entry_point_version" => "0.7",
      "paymaster" => "0xpaymaster",
      "success" => true,
      "actual_gas_cost" => "123456"
    }

    op =
      %Operation{}
      |> Operation.changeset(%{
        transaction_id: tx.id,
        chain_id: chain.chain_id,
        operation_type: :user_operation,
        operation_index: 0,
        from_address: "0xsmartaccount",
        to_address: "0xtoken",
        op_extra: extra
      })
      |> Repo.insert!()

    reloaded = Repo.get!(Operation, op.id)

    assert reloaded.op_extra == extra
    assert reloaded.op_extra["user_op_index"] == 1
    assert reloaded.op_extra["success"] == true
  end

  test "op_extra defaults to an empty map", %{chain: chain, tx: tx} do
    op =
      %Operation{}
      |> Operation.changeset(%{
        transaction_id: tx.id,
        chain_id: chain.chain_id,
        operation_type: :call,
        operation_index: 0,
        from_address: "0xeoa"
      })
      |> Repo.insert!()

    assert Repo.get!(Operation, op.id).op_extra == %{}
  end
end
