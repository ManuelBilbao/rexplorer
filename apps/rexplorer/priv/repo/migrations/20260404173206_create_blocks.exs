defmodule Rexplorer.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :block_number, :bigint, null: false
      add :hash, :string, null: false
      add :parent_hash, :string, null: false
      add :timestamp, :utc_datetime, null: false
      add :gas_used, :bigint, null: false
      add :gas_limit, :bigint, null: false
      add :base_fee_per_gas, :bigint
      add :chain_extra, :map, default: %{}

      timestamps()
    end

    create unique_index(:blocks, [:chain_id, :block_number])
    create unique_index(:blocks, [:chain_id, :hash])
  end
end
