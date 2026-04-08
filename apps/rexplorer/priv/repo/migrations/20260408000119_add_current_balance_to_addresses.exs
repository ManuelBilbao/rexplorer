defmodule Rexplorer.Repo.Migrations.AddCurrentBalanceToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :current_balance_wei, :numeric
    end
  end
end
