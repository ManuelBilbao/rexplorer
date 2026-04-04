defmodule Rexplorer.Schema.Log do
  @moduledoc """
  Represents an event log emitted by a smart contract during transaction execution.

  Logs are uniquely identified by `(chain_id, transaction_id, log_index)`.
  Topics (topic0-topic3) store indexed event parameters; `topic0` is typically
  the event signature hash. The `data` field contains the ABI-encoded
  non-indexed parameters.

  The `decoded` JSONB field is populated by the decoder pipeline with the
  human-readable event interpretation (event name, decoded parameters).
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "logs" do
    belongs_to :transaction, Rexplorer.Schema.Transaction
    belongs_to :chain, Rexplorer.Schema.Chain, references: :chain_id, type: :integer

    field :log_index, :integer
    field :contract_address, :string
    field :topic0, :string
    field :topic1, :string
    field :topic2, :string
    field :topic3, :string
    field :data, :binary
    field :decoded, :map

    timestamps()
  end

  @doc "Changeset for creating or updating a log record."
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:transaction_id, :chain_id, :log_index, :contract_address, :topic0, :topic1, :topic2, :topic3, :data, :decoded])
    |> validate_required([:transaction_id, :chain_id, :log_index, :contract_address])
    |> unique_constraint([:chain_id, :transaction_id, :log_index])
    |> foreign_key_constraint(:transaction_id)
    |> foreign_key_constraint(:chain_id)
  end
end
