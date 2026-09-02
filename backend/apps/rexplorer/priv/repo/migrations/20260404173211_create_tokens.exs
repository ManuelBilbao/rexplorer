defmodule Rexplorer.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :name, :string, null: false
      add :symbol, :string, null: false
      add :decimals, :integer, null: false
      add :logo_url, :string

      timestamps()
    end

    create table(:token_addresses) do
      add :token_id, references(:tokens), null: false
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :contract_address, :string, null: false

      timestamps()
    end

    create unique_index(:token_addresses, [:chain_id, :contract_address])
    create index(:token_addresses, [:token_id])
  end
end
