defmodule Rexplorer.SearchUserOperationTest do
  use Rexplorer.DataCase, async: false

  alias Rexplorer.Search
  alias Rexplorer.Schema.{Block, Chain, Operation, Transaction}

  @chain_id 99993
  @other_chain_id 99994
  @user_op_hash "0x" <> String.duplicate("ab", 32)
  @missing_hash "0x" <> String.duplicate("cd", 32)
  @tx_hash "0x" <> String.duplicate("11", 32)

  setup do
    for {id, slug} <- [{@chain_id, "test-search"}, {@other_chain_id, "test-search-other"}] do
      unless Repo.get(Chain, id) do
        %Chain{}
        |> Chain.changeset(%{
          chain_id: id,
          name: "Test Chain #{id}",
          chain_type: :l1,
          native_token_symbol: "ETH",
          explorer_slug: slug
        })
        |> Repo.insert!()
      end
    end

    tx = insert_bundle(@chain_id, @tx_hash, @user_op_hash)

    %{tx: tx}
  end

  defp insert_bundle(chain_id, tx_hash, user_op_hash) do
    block =
      %Block{}
      |> Block.changeset(%{
        chain_id: chain_id,
        block_number: System.unique_integer([:positive]),
        hash: "0xblock_" <> tx_hash,
        parent_hash: "0xparent",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
        gas_used: 0,
        gas_limit: 30_000_000
      })
      |> Repo.insert!()

    tx =
      %Transaction{}
      |> Transaction.changeset(%{
        chain_id: chain_id,
        block_id: block.id,
        hash: tx_hash,
        from_address: "0xbundler",
        to_address: "0xentrypoint",
        nonce: 0,
        transaction_index: 0
      })
      |> Repo.insert!()

    for {index, user_op_index} <- [{0, 0}, {1, 0}] do
      %Operation{}
      |> Operation.changeset(%{
        transaction_id: tx.id,
        chain_id: chain_id,
        operation_type: :user_operation,
        operation_index: index,
        from_address: "0xsmartaccount",
        to_address: "0xtoken",
        op_extra: %{"user_op_hash" => user_op_hash, "user_op_index" => user_op_index}
      })
      |> Repo.insert!()
    end

    tx
  end

  test "resolves a userOpHash to its parent transaction", %{tx: tx} do
    {:ok, result} = Search.query(@user_op_hash)

    assert result.type == :user_operation
    assert length(result.results) == 2

    operation = hd(result.results)
    assert operation.op_extra["user_op_hash"] == @user_op_hash
    assert operation.transaction.hash == tx.hash
    assert operation.transaction.block.block_number
  end

  test "returns operations ordered by operation_index" do
    {:ok, result} = Search.query(@user_op_hash)

    assert Enum.map(result.results, & &1.operation_index) == [0, 1]
  end

  test "a transaction hash still classifies as a transaction", %{tx: tx} do
    {:ok, result} = Search.query(tx.hash)

    assert result.type == :transaction
    assert [found] = result.results
    assert found.hash == tx.hash
  end

  test "a hash matching nothing returns no results" do
    {:ok, result} = Search.query(@missing_hash)

    assert result.results == []
  end

  test "a userOpHash search can be scoped to a chain" do
    {:ok, scoped} = Search.query(@user_op_hash, chain_id: @chain_id)
    assert length(scoped.results) == 2

    {:ok, elsewhere} = Search.query(@user_op_hash, chain_id: @other_chain_id)
    assert elsewhere.results == []
  end

  test "the transaction branch does not run the userOpHash lookup", %{tx: tx} do
    assert count_queries(fn -> Search.query(tx.hash) end) == 1
    assert count_queries(fn -> Search.query(@user_op_hash) end) == 2
  end

  defp count_queries(fun) do
    ref = make_ref()
    test_pid = self()
    handler_id = {__MODULE__, ref}

    :telemetry.attach(
      handler_id,
      [:rexplorer, :repo, :query],
      fn _event, _measurements, _metadata, _config -> send(test_pid, {ref, :query}) end,
      nil
    )

    fun.()
    :telemetry.detach(handler_id)

    drain(ref, 0)
  end

  defp drain(ref, count) do
    receive do
      {^ref, :query} -> drain(ref, count + 1)
    after
      0 -> count
    end
  end
end
