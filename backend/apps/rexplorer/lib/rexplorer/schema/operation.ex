defmodule Rexplorer.Schema.Operation do
  @moduledoc """
  Represents a single user intent extracted from a transaction.

  This is rexplorer's core abstraction. While traditional explorers treat
  transactions as atomic, rexplorer recognizes that a single transaction can
  contain multiple logical operations:

  - A standard EOA call produces one `call` operation
  - An ERC-4337 `handleOps` produces one `user_operation` per UserOperation
  - A Safe `execTransaction` produces one `multisig_execution` wrapping the inner call
  - A `multicall()` produces one `multicall_item` per batched call

  The `decoded_summary` field holds the human-readable narration (e.g.,
  "Swapped 10 ETH for 25,000 USDC on Uniswap V3"). It is populated at index
  time by the decoder pipeline and tagged with `decoder_version` to support
  background reprocessing when the decoder improves.

  ## `op_extra`

  Structured facts that belong to the operation but have no column of their
  own, mirroring `transactions.chain_extra`. Each key has exactly one writer;
  a key a second consumer needs to filter on earns a column and a migration.

  Written by `Rexplorer.Unwrapper.ERC4337` for `:user_operation` operations:

  | Key | Source |
  |-----|--------|
  | `user_op_hash` | `UserOperationEvent` topic1 (absent without logs) |
  | `user_op_index` | position in the bundle — the grouping key for batched UserOps |
  | `entry_point` | the transaction's `to_address` |
  | `entry_point_version` | `"0.6"`, `"0.7"` or `"0.8"` — the EntryPoint address where known, else the calldata shape |
  | `paymaster` | event topic3, else the `paymasterAndData` prefix (absent when unsponsored) |
  | `factory` | the `initCode` prefix (absent when the account already exists) |
  | `success` | event data — the per-UserOp outcome, independent of the transaction's |
  | `actual_gas_cost` | event data, as a decimal string |

  Keys are omitted rather than set to nil, so `Map.has_key?/2` is meaningful.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type operation_type ::
          :call | :user_operation | :multisig_execution | :multicall_item | :delegate_call

  schema "operations" do
    belongs_to :transaction, Rexplorer.Schema.Transaction
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :operation_type, Ecto.Enum,
      values: [:call, :user_operation, :multisig_execution, :multicall_item, :delegate_call]

    field :operation_index, :integer
    field :from_address, :string
    field :to_address, :string
    field :value, :decimal, default: Decimal.new(0)
    field :input, :binary
    field :decoded_summary, :string
    field :decoder_version, :integer
    field :frame_index, :integer
    field :op_extra, :map, default: %{}

    timestamps()
  end

  @doc "Changeset for creating or updating an operation record."
  def changeset(operation, attrs) do
    operation
    |> cast(attrs, [
      :transaction_id,
      :chain_id,
      :operation_type,
      :operation_index,
      :from_address,
      :to_address,
      :value,
      :input,
      :decoded_summary,
      :decoder_version,
      :frame_index,
      :op_extra
    ])
    |> validate_required([
      :transaction_id,
      :chain_id,
      :operation_type,
      :operation_index,
      :from_address
    ])
    |> foreign_key_constraint(:transaction_id)
    |> foreign_key_constraint(:chain_id)
  end
end
