defmodule Rexplorer.Schema.BatchTest do
  use Rexplorer.DataCase, async: true

  alias Rexplorer.Schema.{Batch, Chain}

  setup do
    # Ensure test chain exists
    chain =
      case Repo.get(Chain, 99990) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: 99990,
            name: "Test Chain",
            chain_type: :zk_rollup,
            native_token_symbol: "ETH",
            explorer_slug: "test-batch"
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    %{chain: chain}
  end

  test "insert a batch", %{chain: chain} do
    {:ok, batch} =
      %Batch{}
      |> Batch.changeset(%{
        chain_id: chain.chain_id,
        batch_number: 1,
        first_block: 100,
        last_block: 110,
        status: :sealed
      })
      |> Repo.insert()

    assert batch.batch_number == 1
    assert batch.status == :sealed
    assert batch.commit_tx_hash == nil
  end

  test "unique constraint on chain_id + batch_number", %{chain: chain} do
    attrs = %{
      chain_id: chain.chain_id,
      batch_number: 2,
      first_block: 200,
      last_block: 210,
      status: :sealed
    }

    %Batch{} |> Batch.changeset(attrs) |> Repo.insert!()

    assert {:error, changeset} = %Batch{} |> Batch.changeset(attrs) |> Repo.insert()
    assert changeset.errors != []
  end

  test "status transitions", %{chain: chain} do
    batch =
      %Batch{}
      |> Batch.changeset(%{
        chain_id: chain.chain_id,
        batch_number: 3,
        first_block: 300,
        last_block: 310,
        status: :sealed
      })
      |> Repo.insert!()

    {:ok, committed} =
      batch
      |> Ecto.Changeset.change(%{status: :committed, commit_tx_hash: "0xabc123"})
      |> Repo.update()

    assert committed.status == :committed
    assert committed.commit_tx_hash == "0xabc123"

    {:ok, verified} =
      committed
      |> Ecto.Changeset.change(%{status: :verified, verify_tx_hash: "0xdef456"})
      |> Repo.update()

    assert verified.status == :verified
    assert verified.verify_tx_hash == "0xdef456"
  end
end
