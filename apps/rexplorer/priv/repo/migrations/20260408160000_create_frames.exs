defmodule Rexplorer.Repo.Migrations.CreateFrames do
  use Ecto.Migration

  def change do
    create table(:frames) do
      add :chain_id, references(:chains, column: :chain_id, type: :integer), null: false
      add :transaction_id, references(:transactions), null: false
      add :frame_index, :integer, null: false
      add :mode, :integer, null: false
      add :target, :string
      add :gas_limit, :bigint
      add :gas_used, :bigint
      add :status, :boolean
      add :data, :binary

      timestamps()
    end

    create unique_index(:frames, [:chain_id, :transaction_id, :frame_index])
    create index(:frames, [:chain_id, :target])
  end
end
