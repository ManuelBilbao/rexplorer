defmodule Rexplorer.Decoder.Worker do
  @moduledoc """
  Async background worker that processes operations needing decoding.

  Polls the database for operations where `decoder_version IS NULL OR
  decoder_version < current_version`, runs the decoder pipeline on each,
  and updates `decoded_summary` + `decoder_version`.

  The same mechanism handles both initial decoding (new operations) and
  reprocessing (when the decoder is upgraded to a new version).
  """

  use GenServer
  require Logger

  import Ecto.Query
  alias Rexplorer.{Repo, Schema.Operation}
  alias Rexplorer.Decoder.{Pipeline, Narrator}

  @batch_size 100
  @poll_interval_ms 5_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("[Decoder] Worker started (version #{Pipeline.decoder_version()})")
    schedule_poll(0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:poll, state) do
    count = process_batch()

    if count >= @batch_size do
      # More operations likely available, process immediately
      schedule_poll(0)
    else
      # Caught up, wait before next poll
      schedule_poll(@poll_interval_ms)
    end

    {:noreply, state}
  end

  defp process_batch do
    version = Pipeline.decoder_version()

    operations =
      from(o in Operation,
        where: is_nil(o.decoder_version) or o.decoder_version < ^version,
        limit: ^@batch_size,
        select: o
      )
      |> Repo.all()

    if operations == [] do
      0
    else
      # Build token caches per chain (deduplicated)
      chain_ids = operations |> Enum.map(& &1.chain_id) |> Enum.uniq()
      token_caches = Map.new(chain_ids, fn cid -> {cid, Narrator.build_token_cache(cid)} end)

      Enum.each(operations, fn op ->
        decode_and_update(op, token_caches)
      end)

      length(operations)
    end
  end

  defp decode_and_update(operation, token_caches) do
    token_cache = Map.get(token_caches, operation.chain_id, %{})
    version = Pipeline.decoder_version()

    case Pipeline.decode_operation(operation, token_cache) do
      {:ok, summary} ->
        operation
        |> Ecto.Changeset.change(%{decoded_summary: summary, decoder_version: version})
        |> Repo.update()

      {:error, reason} ->
        Logger.warning(
          "[Decoder] Failed to decode operation #{operation.id}: #{inspect(reason)}"
        )

        # Mark with current version to avoid reprocessing
        operation
        |> Ecto.Changeset.change(%{decoded_summary: nil, decoder_version: version})
        |> Repo.update()
    end
  rescue
    e ->
      Logger.error(
        "[Decoder] Error processing operation #{operation.id}: #{Exception.message(e)}"
      )

      # Mark with current version to avoid infinite retry
      try do
        operation
        |> Ecto.Changeset.change(%{decoded_summary: nil, decoder_version: Pipeline.decoder_version()})
        |> Repo.update()
      rescue
        _ -> :ok
      end
  end

  defp schedule_poll(delay) do
    Process.send_after(self(), :poll, delay)
  end
end
