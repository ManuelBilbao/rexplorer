defmodule Rexplorer.Repo.Migrations.CreateCrossChainLinks do
  use Ecto.Migration

  def change do
    create table(:cross_chain_links) do
      add :source_chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :source_tx_hash, :string, null: false
      add :destination_chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :destination_tx_hash, :string
      add :link_type, :cross_chain_link_type, null: false
      add :message_hash, :string, null: false
      add :status, :cross_chain_link_status, null: false, default: "initiated"

      timestamps()
    end

    create index(:cross_chain_links, [:source_chain_id, :source_tx_hash])
    create index(:cross_chain_links, [:destination_chain_id, :destination_tx_hash])
    create index(:cross_chain_links, [:message_hash])
  end
end
