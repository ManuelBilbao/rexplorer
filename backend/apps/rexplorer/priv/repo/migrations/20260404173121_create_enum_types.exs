defmodule Rexplorer.Repo.Migrations.CreateEnumTypes do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE chain_type AS ENUM (
      'l1',
      'optimistic_rollup',
      'zk_rollup',
      'sidechain'
    )
    """

    execute """
    CREATE TYPE operation_type AS ENUM (
      'call',
      'user_operation',
      'multisig_execution',
      'multicall_item',
      'delegate_call'
    )
    """

    execute """
    CREATE TYPE token_type AS ENUM (
      'native',
      'erc20',
      'erc721',
      'erc1155'
    )
    """

    execute """
    CREATE TYPE cross_chain_link_type AS ENUM (
      'deposit',
      'withdrawal',
      'relay'
    )
    """

    execute """
    CREATE TYPE cross_chain_link_status AS ENUM (
      'initiated',
      'relayed',
      'proven',
      'finalized'
    )
    """
  end

  def down do
    execute "DROP TYPE cross_chain_link_status"
    execute "DROP TYPE cross_chain_link_type"
    execute "DROP TYPE token_type"
    execute "DROP TYPE operation_type"
    execute "DROP TYPE chain_type"
  end
end
