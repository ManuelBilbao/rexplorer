defmodule RexplorerWeb.Internal.TransactionDetailController do
  use RexplorerWeb, :controller
  action_fallback RexplorerWeb.FallbackController

  def show(conn, %{"hash" => hash, "chain_slug" => slug}) do
    with {:ok, chain} <- Rexplorer.Chains.get_chain_by_slug(slug),
         {:ok, tx, cross_chain_links} <- Rexplorer.Transactions.get_full_transaction(chain.chain_id, hash) do
      json(conn, %{
        transaction: tx_json(tx),
        operations: Enum.map(tx.operations, &op_json/1),
        token_transfers: Enum.map(tx.token_transfers, &transfer_json/1),
        logs: Enum.map(tx.logs, &log_json/1),
        cross_chain_links: Enum.map(cross_chain_links, &link_json/1)
      })
    end
  end

  defp tx_json(tx) do
    %{
      hash: tx.hash,
      from_address: tx.from_address,
      to_address: tx.to_address,
      value: to_string(tx.value),
      gas_price: tx.gas_price,
      gas_used: tx.gas_used,
      nonce: tx.nonce,
      status: tx.status,
      block_number: tx.block.block_number,
      block_timestamp: tx.block.timestamp
    }
  end

  defp op_json(op) do
    %{
      operation_type: op.operation_type,
      operation_index: op.operation_index,
      from_address: op.from_address,
      to_address: op.to_address,
      value: to_string(op.value),
      decoded_summary: op.decoded_summary
    }
  end

  defp transfer_json(t) do
    %{
      from_address: t.from_address,
      to_address: t.to_address,
      token_contract_address: t.token_contract_address,
      amount: to_string(t.amount),
      token_type: t.token_type,
      token_id: t.token_id
    }
  end

  defp log_json(l) do
    %{
      log_index: l.log_index,
      contract_address: l.contract_address,
      topic0: l.topic0,
      topic1: l.topic1,
      topic2: l.topic2,
      topic3: l.topic3,
      decoded: l.decoded
    }
  end

  defp link_json(l) do
    %{
      source_chain_id: l.source_chain_id,
      source_tx_hash: l.source_tx_hash,
      destination_chain_id: l.destination_chain_id,
      destination_tx_hash: l.destination_tx_hash,
      link_type: l.link_type,
      status: l.status,
      message_hash: l.message_hash
    }
  end
end
