defmodule Rexplorer.Repo.Migrations.CreateOperations do
  use Ecto.Migration

  def change do
    create table(:operations) do
      add :transaction_id, references(:transactions), null: false
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :operation_type, :operation_type, null: false
      add :operation_index, :integer, null: false
      add :from_address, :string, null: false
      add :to_address, :string
      add :value, :numeric, null: false, default: 0
      add :input, :binary
      add :decoded_summary, :text
      add :decoder_version, :integer

      timestamps()
    end

    create index(:operations, [:transaction_id, :operation_index])
    create index(:operations, [:chain_id, :from_address])
    create index(:operations, [:chain_id, :to_address])
    create index(:operations, [:decoder_version])
  end
end
