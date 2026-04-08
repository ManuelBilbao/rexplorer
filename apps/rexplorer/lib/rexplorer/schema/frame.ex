defmodule Rexplorer.Schema.Frame do
  @moduledoc """
  A single execution frame within an EIP-8141 frame transaction.

  Frame transactions (type `0x06`) contain an ordered list of frames, each
  executed sequentially. Frames replace the traditional `{to, value, input}`
  model with per-frame `{mode, target, gasLimit, data}` and produce per-frame
  receipts with `{status, gasUsed, logs}`.

  ## Frame Modes

  - `0` (DEFAULT) — executed from the entry point (`0x...aa`). Used for
    account deployment and paymaster post-operations.
  - `1` (VERIFY) — validates the transaction (signatures, permissions).
    Runs in static mode — no state changes. Must call APPROVE or the tx
    is invalid.
  - `2` (SENDER) — executed on behalf of `tx.sender`. This is where user
    operations happen (swaps, transfers, etc.).

  ## Fields

  - `chain_id` — the chain this frame belongs to
  - `transaction_id` — FK to the parent transaction
  - `frame_index` — position in the frame list (0-based)
  - `mode` — frame mode (0=DEFAULT, 1=VERIFY, 2=SENDER)
  - `target` — the address being called
  - `gas_limit` — gas allocated to this frame
  - `gas_used` — gas consumed (from frame receipt)
  - `status` — success/failure (from frame receipt)
  - `data` — full calldata (bytea)
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "frames" do
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer
    belongs_to :transaction, Rexplorer.Schema.Transaction

    field :frame_index, :integer
    field :mode, :integer
    field :target, :string
    field :gas_limit, :integer
    field :gas_used, :integer
    field :status, :boolean
    field :data, :binary

    timestamps()
  end

  @doc "Changeset for creating a frame record."
  def changeset(frame, attrs) do
    frame
    |> cast(attrs, [:chain_id, :transaction_id, :frame_index, :mode, :target, :gas_limit, :gas_used, :status, :data])
    |> validate_required([:chain_id, :transaction_id, :frame_index, :mode])
    |> validate_inclusion(:mode, [0, 1, 2])
    |> unique_constraint([:chain_id, :transaction_id, :frame_index])
    |> foreign_key_constraint(:chain_id)
    |> foreign_key_constraint(:transaction_id)
  end

  @doc "Returns a human-readable label for a frame mode."
  def mode_label(0), do: "DEFAULT"
  def mode_label(1), do: "VERIFY"
  def mode_label(2), do: "SENDER"
  def mode_label(_), do: "UNKNOWN"
end
