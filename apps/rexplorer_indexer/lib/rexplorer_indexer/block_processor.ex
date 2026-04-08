defmodule RexplorerIndexer.BlockProcessor do
  @moduledoc """
  Pure transformation functions that convert raw RPC block and receipt data
  into Ecto-ready attribute maps.

  This module has no side effects — it does not make database calls, RPC calls,
  or modify state. All functions take raw data in and return structured attribute
  maps out, making them easy to test with fixture data.

  ## Usage

      {:ok, raw_block} = Rexplorer.RPC.Client.get_block(url, number)
      {:ok, receipts} = Rexplorer.RPC.Client.get_block_receipts(url, number)
      result = RexplorerIndexer.BlockProcessor.process_block(raw_block, receipts, adapter)
      # result.block, result.transactions, result.operations, etc.
  """

  alias Rexplorer.RPC.Client

  @doc """
  Processes a raw RPC block and its receipts into Ecto-ready attribute maps.

  Returns a map with keys:
  - `:block` — block attribute map
  - `:transactions` — list of transaction attribute maps
  - `:operations` — list of operation attribute maps
  - `:logs` — list of log attribute maps
  - `:token_transfers` — list of token transfer attribute maps
  - `:addresses` — list of unique address attribute maps
  """
  def process_block(raw_block, receipts, adapter) do
    chain_id = adapter.chain_id()
    block_timestamp = parse_timestamp(raw_block["timestamp"])

    block_attrs = extract_block(raw_block, chain_id, adapter)

    receipt_map = index_receipts_by_hash(receipts)

    {transactions, operations, logs, token_transfers, frames} =
      raw_block["transactions"]
      |> Enum.with_index()
      |> Enum.reduce({[], [], [], [], []}, fn {raw_tx, _idx}, {txs, ops, lgs, xfers, frms} ->
        receipt = Map.get(receipt_map, raw_tx["hash"])

        if is_frame_tx?(raw_tx) do
          # EIP-8141 frame transaction
          tx_attrs = extract_frame_transaction(raw_tx, receipt, chain_id, adapter)
          tx_hash = tx_attrs.hash

          tx_frames = extract_frames(raw_tx, receipt, chain_id)
            |> Enum.map(&Map.put(&1, :tx_hash, tx_hash))

          {tx_logs, tx_operations, tx_token_transfers} =
            extract_per_frame_data(raw_tx, receipt, tx_attrs, adapter, chain_id)

          tx_logs = Enum.map(tx_logs, &Map.put(&1, :tx_hash, tx_hash))
          tx_operations = Enum.map(tx_operations, &Map.put(&1, :tx_hash, tx_hash))
          tx_token_transfers = Enum.map(tx_token_transfers, &Map.put(&1, :tx_hash, tx_hash))

          {[tx_attrs | txs], ops ++ tx_operations, lgs ++ tx_logs, xfers ++ tx_token_transfers, frms ++ tx_frames}
        else
          # Regular transaction
          tx_attrs = extract_transaction(raw_tx, receipt, chain_id, adapter)
          tx_hash = tx_attrs.hash

          tx_operations =
            extract_operations(tx_attrs, adapter)
            |> Enum.map(&Map.put(&1, :tx_hash, tx_hash))

          tx_logs =
            extract_logs(receipt, chain_id)
            |> Enum.map(&Map.put(&1, :tx_hash, tx_hash))

          tx_token_transfers =
            extract_token_transfers(tx_attrs, tx_logs, adapter, chain_id)
            |> Enum.map(&Map.put(&1, :tx_hash, tx_hash))

          {[tx_attrs | txs], ops ++ tx_operations, lgs ++ tx_logs, xfers ++ tx_token_transfers, frms}
        end
      end)

    transactions = Enum.reverse(transactions)

    addresses = discover_addresses(transactions, logs, token_transfers, chain_id, block_timestamp)

    %{
      block: block_attrs,
      transactions: transactions,
      operations: operations,
      logs: logs,
      token_transfers: token_transfers,
      frames: frames,
      addresses: addresses
    }
  end

  @doc "Extracts block attributes from raw RPC block data."
  def extract_block(raw_block, chain_id, adapter) do
    chain_extra = extract_chain_extra(raw_block, adapter.block_fields())

    %{
      chain_id: chain_id,
      block_number: Client.hex_to_integer(raw_block["number"]),
      hash: raw_block["hash"],
      parent_hash: raw_block["parentHash"],
      timestamp: parse_timestamp(raw_block["timestamp"]),
      gas_used: Client.hex_to_integer(raw_block["gasUsed"]),
      gas_limit: Client.hex_to_integer(raw_block["gasLimit"]),
      base_fee_per_gas: Client.hex_to_integer(raw_block["baseFeePerGas"]),
      chain_extra: chain_extra
    }
  end

  @doc "Extracts transaction attributes from raw RPC transaction + receipt data."
  def extract_transaction(raw_tx, receipt, chain_id, adapter) do
    chain_extra =
      extract_chain_extra(raw_tx, adapter.transaction_fields())
      |> enrich_tx_chain_extra(raw_tx)

    %{
      chain_id: chain_id,
      hash: raw_tx["hash"],
      from_address: downcase(raw_tx["from"]),
      to_address: downcase(raw_tx["to"]),
      value: parse_value(raw_tx["value"]),
      input: Client.hex_to_binary(raw_tx["input"]),
      gas_price: Client.hex_to_integer(raw_tx["gasPrice"]),
      nonce: Client.hex_to_integer(raw_tx["nonce"]),
      transaction_type: Client.hex_to_integer(raw_tx["type"]),
      transaction_index: Client.hex_to_integer(raw_tx["transactionIndex"]),
      chain_extra: chain_extra,
      # From receipt
      status: parse_status(receipt),
      gas_used: Client.hex_to_integer(receipt && receipt["gasUsed"])
    }
  end

  @doc "Extracts operations from a processed transaction via the chain adapter."
  def extract_operations(tx_attrs, adapter) do
    tx_map = %{
      from_address: tx_attrs.from_address,
      to_address: tx_attrs.to_address,
      value: tx_attrs.value,
      input: tx_attrs.input
    }

    adapter.extract_operations(tx_map)
    |> Enum.map(fn op ->
      Map.merge(op, %{chain_id: tx_attrs.chain_id})
    end)
  end

  @doc "Extracts log attributes from a transaction receipt."
  def extract_logs(nil, _chain_id), do: []

  def extract_logs(receipt, chain_id) do
    (receipt["logs"] || [])
    |> Enum.map(fn raw_log ->
      %{
        chain_id: chain_id,
        log_index: Client.hex_to_integer(raw_log["logIndex"]),
        contract_address: downcase(raw_log["address"]),
        topic0: Enum.at(raw_log["topics"] || [], 0),
        topic1: Enum.at(raw_log["topics"] || [], 1),
        topic2: Enum.at(raw_log["topics"] || [], 2),
        topic3: Enum.at(raw_log["topics"] || [], 3),
        data: Client.hex_to_binary(raw_log["data"])
      }
    end)
  end

  @doc "Extracts token transfers via the chain adapter."
  def extract_token_transfers(tx_attrs, tx_logs, adapter, chain_id) do
    # Build a transaction-like map with logs for the adapter
    tx_with_logs = %{
      from_address: tx_attrs.from_address,
      to_address: tx_attrs.to_address,
      value: tx_attrs.value,
      logs: Enum.map(tx_logs, fn log ->
        %{
          contract_address: log.contract_address,
          topic0: log.topic0,
          topic1: log.topic1,
          topic2: log.topic2,
          topic3: log.topic3,
          data: encode_data_as_hex(log.data)
        }
      end)
    }

    adapter.extract_token_transfers(tx_with_logs)
    |> Enum.map(fn transfer ->
      Map.put(transfer, :chain_id, chain_id)
    end)
  end

  @doc "Discovers unique addresses from all processed data within a block."
  def discover_addresses(transactions, logs, token_transfers, chain_id, block_timestamp) do
    address_set =
      MapSet.new()
      |> collect_tx_addresses(transactions)
      |> collect_log_addresses(logs)
      |> collect_transfer_addresses(token_transfers)
      |> MapSet.delete(nil)

    Enum.map(address_set, fn hash ->
      %{
        chain_id: chain_id,
        hash: hash,
        is_contract: false,
        first_seen_at: block_timestamp
      }
    end)
  end

  # Private helpers

  defp index_receipts_by_hash(receipts) when is_list(receipts) do
    Map.new(receipts, fn r -> {r["transactionHash"], r} end)
  end

  defp index_receipts_by_hash(_), do: %{}

  defp parse_timestamp(hex) do
    unix = Client.hex_to_integer(hex)
    DateTime.from_unix!(unix) |> DateTime.truncate(:second)
  end

  defp parse_value(nil), do: Decimal.new(0)

  defp parse_value("0x" <> hex) do
    hex
    |> String.to_integer(16)
    |> Decimal.new()
  end

  defp parse_status(nil), do: nil
  defp parse_status(%{"status" => "0x1"}), do: true
  defp parse_status(%{"status" => "0x0"}), do: false
  defp parse_status(_), do: nil

  defp downcase(nil), do: nil
  defp downcase(s) when is_binary(s), do: String.downcase(s)

  # Derive computed chain_extra fields from raw tx data
  defp enrich_tx_chain_extra(chain_extra, _raw_tx) when chain_extra == %{}, do: chain_extra

  defp enrich_tx_chain_extra(chain_extra, raw_tx) do
    tx_type = Client.hex_to_integer(raw_tx["type"])

    chain_extra
    |> maybe_put(:is_privileged, tx_type == 0x7E)
    |> maybe_put(:fee_token, if(tx_type == 0x7D, do: downcase(raw_tx["feeToken"]), else: nil))
    |> maybe_put(:l1_origin_hash, raw_tx["sourceHash"] || raw_tx["l1OriginHash"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, false), do: Map.put(map, key, false)
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp extract_chain_extra(_raw, []), do: %{}

  defp extract_chain_extra(raw, field_defs) do
    Map.new(field_defs, fn {field_name, _type} ->
      key = Atom.to_string(field_name)
      {field_name, raw[key]}
    end)
  end

  defp encode_data_as_hex(nil), do: nil
  defp encode_data_as_hex(<<>>), do: "0x"
  defp encode_data_as_hex(binary) when is_binary(binary), do: "0x" <> Base.encode16(binary, case: :lower)

  defp collect_tx_addresses(set, transactions) do
    Enum.reduce(transactions, set, fn tx, acc ->
      acc
      |> MapSet.put(tx.from_address)
      |> MapSet.put(tx.to_address)
    end)
  end

  defp collect_log_addresses(set, logs) do
    Enum.reduce(logs, set, fn log, acc ->
      MapSet.put(acc, log.contract_address)
    end)
  end

  defp collect_transfer_addresses(set, transfers) do
    Enum.reduce(transfers, set, fn xfer, acc ->
      acc
      |> MapSet.put(xfer.from_address)
      |> MapSet.put(xfer.to_address)
    end)
  end

  # ── EIP-8141 Frame Transaction Support ──
  #
  # Frame transactions (type 0x06) contain sequential execution frames instead
  # of a single {to, value, input}. Each frame has its own mode, target, gas,
  # status, and logs.
  #
  # ```mermaid
  # sequenceDiagram
  #     participant BP as BlockProcessor
  #     BP->>BP: is_frame_tx?(raw_tx) — check type == "0x6"
  #     BP->>BP: extract_frame_transaction — from_address=sender, to=nil, payer from receipt
  #     BP->>BP: extract_frames — parse tx.frames + receipt.frameReceipts
  #     loop Each frame
  #         alt SENDER frame
  #             BP->>BP: extract_operations(sender, target, data, logs)
  #             BP->>BP: extract_token_transfers(logs)
  #         end
  #         alt DEFAULT frame
  #             BP->>BP: extract_operations(entry_point, target, data, logs)
  #         end
  #         BP->>BP: extract_logs with frame_index
  #     end
  # ```

  @doc "Returns true if the raw transaction is an EIP-8141 frame transaction (type 0x06)."
  def is_frame_tx?(%{"type" => "0x6"}), do: true
  def is_frame_tx?(%{"type" => type}) when is_binary(type) do
    Client.hex_to_integer(type) == 6
  rescue
    _ -> false
  end
  def is_frame_tx?(_), do: false

  @doc "Extracts transaction attributes from a frame transaction."
  def extract_frame_transaction(raw_tx, receipt, chain_id, adapter) do
    chain_extra =
      extract_chain_extra(raw_tx, adapter.transaction_fields())
      |> enrich_tx_chain_extra(raw_tx)

    %{
      chain_id: chain_id,
      hash: raw_tx["hash"],
      from_address: downcase(raw_tx["sender"] || raw_tx["from"]),
      to_address: nil,
      value: Decimal.new(0),
      input: nil,
      gas_price: Client.hex_to_integer(raw_tx["maxFeePerGas"]),
      nonce: Client.hex_to_integer(raw_tx["nonce"]),
      transaction_type: 6,
      transaction_index: Client.hex_to_integer(raw_tx["transactionIndex"]),
      chain_extra: chain_extra,
      payer: downcase(receipt && receipt["payer"]),
      status: parse_status(receipt),
      gas_used: Client.hex_to_integer(receipt && receipt["gasUsed"])
    }
  end

  @doc "Extracts frame attribute maps from a frame transaction and its receipt."
  def extract_frames(raw_tx, receipt, chain_id) do
    raw_frames = raw_tx["frames"] || []
    frame_receipts = (receipt && receipt["frameReceipts"]) || []

    raw_frames
    |> Enum.with_index()
    |> Enum.map(fn {frame, idx} ->
      frame_receipt = Enum.at(frame_receipts, idx) || %{}

      %{
        chain_id: chain_id,
        frame_index: idx,
        mode: Client.hex_to_integer(frame["mode"]),
        target: downcase(frame["to"]),
        gas_limit: Client.hex_to_integer(frame["gasLimit"]),
        gas_used: Client.hex_to_integer(frame_receipt["gasUsed"]),
        status: parse_status(frame_receipt),
        data: Client.hex_to_binary(frame["data"])
      }
    end)
  end

  @doc "Extracts logs, operations, and token transfers per-frame from a frame transaction."
  def extract_per_frame_data(raw_tx, receipt, tx_attrs, adapter, chain_id) do
    raw_frames = raw_tx["frames"] || []
    frame_receipts = (receipt && receipt["frameReceipts"]) || []
    sender = tx_attrs.from_address
    entry_point = "0x00000000000000000000000000000000000000aa"

    raw_frames
    |> Enum.with_index()
    |> Enum.reduce({[], [], []}, fn {frame, idx}, {logs_acc, ops_acc, xfers_acc} ->
      frame_receipt = Enum.at(frame_receipts, idx) || %{}
      mode = Client.hex_to_integer(frame["mode"])
      target = downcase(frame["to"])
      frame_data = Client.hex_to_binary(frame["data"])

      # Extract logs for this frame, assigning synthetic log_index
      # (frame receipt logs may not include logIndex)
      global_log_offset = length(logs_acc)
      frame_logs =
        extract_logs(frame_receipt, chain_id)
        |> Enum.with_index(global_log_offset)
        |> Enum.map(fn {log, synthetic_idx} ->
          log
          |> Map.put(:frame_index, idx)
          |> Map.put(:log_index, log.log_index || synthetic_idx)
        end)

      # Extract operations for SENDER and DEFAULT frames (skip VERIFY)
      frame_ops =
        if mode in [0, 2] do
          from_addr = if mode == 2, do: sender, else: entry_point

          op_tx = %{
            from_address: from_addr,
            to_address: target,
            value: Decimal.new(0),
            input: frame_data,
            chain_id: chain_id
          }

          adapter.extract_operations(op_tx)
          |> Enum.map(fn op ->
            op
            |> Map.merge(%{chain_id: chain_id, frame_index: idx})
          end)
        else
          []
        end

      # Extract token transfers from frame logs
      frame_xfers =
        if frame_logs != [] do
          tx_with_logs = %{
            from_address: sender,
            to_address: target,
            value: Decimal.new(0),
            logs: Enum.map(frame_logs, fn log ->
              %{
                contract_address: log.contract_address,
                topic0: log.topic0,
                topic1: log.topic1,
                topic2: log.topic2,
                topic3: log.topic3,
                data: encode_data_as_hex(log.data)
              }
            end)
          }

          adapter.extract_token_transfers(tx_with_logs)
          |> Enum.map(&Map.merge(&1, %{chain_id: chain_id, frame_index: idx}))
        else
          []
        end

      {logs_acc ++ frame_logs, ops_acc ++ frame_ops, xfers_acc ++ frame_xfers}
    end)
  end
end
