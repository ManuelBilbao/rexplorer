defmodule Rexplorer.Repo.Migrations.AddOpExtraToOperations do
  use Ecto.Migration

  def change do
    alter table(:operations) do
      add :op_extra, :map, null: false, default: %{}
    end

    # Partial expression index for userOpHash lookups from search. Partial
    # because ERC-4337 operations are a small fraction of all operations.
    create index(
             :operations,
             [:chain_id, "(op_extra->>'user_op_hash')"],
             name: :operations_user_op_hash_idx,
             where: "op_extra ? 'user_op_hash'"
           )
  end
end
