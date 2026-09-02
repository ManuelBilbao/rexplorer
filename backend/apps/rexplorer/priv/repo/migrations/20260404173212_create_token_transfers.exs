defmodule Rexplorer.Repo.Migrations.CreateTokenTransfers do
  use Ecto.Migration

  def change do
    create table(:token_transfers) do
      add :transaction_id, references(:transactions), null: false
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :from_address, :string, null: false
      add :to_address, :string, null: false
      add :token_contract_address, :string, null: false
      add :amount, :numeric, null: false
      add :token_type, :token_type, null: false
      add :token_id, :string

      timestamps()
    end

    create index(:token_transfers, [:chain_id, :from_address])
    create index(:token_transfers, [:chain_id, :to_address])
    create index(:token_transfers, [:transaction_id])
    create index(:token_transfers, [:chain_id, :token_contract_address])
  end
end
