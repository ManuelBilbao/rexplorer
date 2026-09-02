defmodule Rexplorer.Repo.Migrations.AddFrameIndexToLogsOperationsTransfers do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      add :frame_index, :integer
    end

    alter table(:operations) do
      add :frame_index, :integer
    end

    alter table(:token_transfers) do
      add :frame_index, :integer
    end
  end
end
