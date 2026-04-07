defmodule Rexplorer.Repo.Migrations.CreateBatchStatusAndBatches do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE batch_status AS ENUM (
      'sealed',
      'committed',
      'verified'
    )
    """

    create table(:batches) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :batch_number, :integer, null: false
      add :first_block, :bigint, null: false
      add :last_block, :bigint, null: false
      add :status, :batch_status, null: false, default: "sealed"
      add :commit_tx_hash, :string
      add :verify_tx_hash, :string

      timestamps()
    end

    create unique_index(:batches, [:chain_id, :batch_number])
    create index(:batches, [:chain_id, :status])
  end

  def down do
    drop table(:batches)
    execute "DROP TYPE batch_status"
  end
end
