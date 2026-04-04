defmodule Rexplorer.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs) do
      add :transaction_id, references(:transactions), null: false
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :log_index, :integer, null: false
      add :contract_address, :string, null: false
      add :topic0, :string
      add :topic1, :string
      add :topic2, :string
      add :topic3, :string
      add :data, :binary
      add :decoded, :map

      timestamps()
    end

    create unique_index(:logs, [:chain_id, :transaction_id, :log_index])
    create index(:logs, [:chain_id, :contract_address, :topic0])
  end
end
