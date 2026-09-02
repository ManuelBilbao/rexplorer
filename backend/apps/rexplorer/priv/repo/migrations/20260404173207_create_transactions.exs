defmodule Rexplorer.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :hash, :string, null: false
      add :block_id, references(:blocks), null: false
      add :from_address, :string, null: false
      add :to_address, :string
      add :value, :numeric, null: false, default: 0
      add :input, :binary
      add :gas_price, :bigint
      add :gas_used, :bigint
      add :nonce, :integer, null: false
      add :transaction_type, :integer
      add :status, :boolean
      add :transaction_index, :integer, null: false
      add :chain_extra, :map, default: %{}

      timestamps()
    end

    create unique_index(:transactions, [:chain_id, :hash])
    create index(:transactions, [:chain_id, :from_address])
    create index(:transactions, [:chain_id, :to_address])
    create index(:transactions, [:block_id])
  end
end
