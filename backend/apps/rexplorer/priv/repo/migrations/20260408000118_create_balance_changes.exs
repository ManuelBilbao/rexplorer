defmodule Rexplorer.Repo.Migrations.CreateBalanceChanges do
  use Ecto.Migration

  def change do
    create table(:balance_changes) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :address_hash, :string, null: false
      add :block_number, :bigint, null: false
      add :balance_wei, :numeric, null: false
      add :timestamp, :utc_datetime, null: false
      add :source, :string, null: false, default: "indexed"

      timestamps()
    end

    create unique_index(:balance_changes, [:chain_id, :address_hash, :block_number])
    create index(:balance_changes, [:chain_id, :address_hash, :timestamp])
  end
end
