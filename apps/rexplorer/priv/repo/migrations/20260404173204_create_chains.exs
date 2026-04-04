defmodule Rexplorer.Repo.Migrations.CreateChains do
  use Ecto.Migration

  def change do
    create table(:chains, primary_key: false) do
      add :chain_id, :integer, primary_key: true
      add :name, :string, null: false
      add :chain_type, :chain_type, null: false
      add :native_token_symbol, :string, null: false
      add :explorer_slug, :string, null: false
      add :rpc_config, :map, default: %{}
      add :enabled, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:chains, [:explorer_slug])
  end
end
