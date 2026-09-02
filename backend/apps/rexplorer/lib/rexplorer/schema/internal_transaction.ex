defmodule Rexplorer.Schema.InternalTransaction do
  @moduledoc """
  A value-transferring internal transaction extracted from block trace data.

  Internal transactions represent ETH movements that happen *inside* the EVM
  during transaction execution — contract-to-contract calls with value, contract
  creations, and self-destructs. These are invisible at the top-level transaction
  layer (the `transactions` table) but critical for showing deposit recipients
  and internal ETH transfers on address pages.

  Only value-transferring entries are stored (value > 0, CREATE, SELFDESTRUCT).
  Zero-value calls and static/delegate calls are excluded to keep storage lean.

  ## Fields

  - `chain_id` — the chain this trace belongs to
  - `block_number` — block where the parent transaction was included
  - `transaction_hash` — hash of the parent transaction
  - `transaction_index` — position of the parent tx within the block
  - `trace_index` — sequential index of this entry within the block's traces
  - `from_address` — address initiating the internal call
  - `to_address` — recipient address (nullable for failed creates)
  - `value` — wei transferred
  - `call_type` — one of: `call`, `create`, `create2`, `selfdestruct`
  - `trace_address` — integer array path in the call tree (e.g., [0, 1, 2])
  - `input_prefix` — first 4 bytes of calldata (function selector), nullable
  - `error` — error message if the call reverted, nullable
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "internal_transactions" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :block_number, :integer
    field :transaction_hash, :string
    field :transaction_index, :integer
    field :trace_index, :integer
    field :from_address, :string
    field :to_address, :string
    field :value, :decimal
    field :call_type, :string
    field :trace_address, {:array, :integer}, default: []
    field :input_prefix, :binary
    field :error, :string

    timestamps()
  end

  @doc "Changeset for creating an internal transaction record."
  def changeset(internal_transaction, attrs) do
    internal_transaction
    |> cast(attrs, [
      :chain_id, :block_number, :transaction_hash, :transaction_index,
      :trace_index, :from_address, :to_address, :value, :call_type,
      :trace_address, :input_prefix, :error
    ])
    |> validate_required([:chain_id, :block_number, :transaction_hash, :transaction_index, :trace_index, :from_address, :value, :call_type])
    |> validate_inclusion(:call_type, ["call", "create", "create2", "selfdestruct"])
    |> unique_constraint([:chain_id, :block_number, :transaction_index, :trace_index])
    |> foreign_key_constraint(:chain_id)
  end
end
