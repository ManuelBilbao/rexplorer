defmodule Rexplorer.Repo.Migrations.AddPayerToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :payer, :string
    end
  end
end
