defmodule Rexplorer.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :hash, :string, null: false
      add :is_contract, :boolean, default: false, null: false
      add :contract_code_hash, :string
      add :label, :string
      add :first_seen_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:addresses, [:chain_id, :hash])
  end
end
