defmodule Rexplorer.Repo.Migrations.CreateInternalTransactions do
  use Ecto.Migration

  def change do
    create table(:internal_transactions) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :block_number, :bigint, null: false
      add :transaction_hash, :string, null: false
      add :transaction_index, :integer, null: false
      add :trace_index, :integer, null: false
      add :from_address, :string, null: false
      add :to_address, :string
      add :value, :numeric, null: false, default: 0
      add :call_type, :string, null: false
      add :trace_address, {:array, :integer}, null: false, default: []
      add :input_prefix, :bytea
      add :error, :string

      timestamps()
    end

    create unique_index(:internal_transactions, [:chain_id, :block_number, :transaction_index, :trace_index])
    create index(:internal_transactions, [:chain_id, :from_address, :block_number])
    create index(:internal_transactions, [:chain_id, :to_address, :block_number])
  end
end
