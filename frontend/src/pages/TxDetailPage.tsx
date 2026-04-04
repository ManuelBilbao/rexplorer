import { useState } from 'react'
import { useParams } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useTxDetail } from '../api/queries'
import { formatAmount, formatGas } from '../lib/format'

export function TxDetailPage() {
  const chain = useChain()
  const { hash } = useParams()
  const { data, isLoading } = useTxDetail(chain, hash)
  const [advanced, setAdvanced] = useState(false)

  if (isLoading) {
    return <div className="space-y-4">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="h-6 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse" />
      ))}
    </div>
  }

  if (!data) return <div className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Transaction not found</div>

  const tx = data.transaction

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-rex-text dark:text-rex-text-dark">Transaction</h1>
        <button
          onClick={() => setAdvanced(!advanced)}
          className="px-3 py-1 text-sm rounded-lg border border-rex-border dark:border-rex-border-dark hover:bg-rex-bg-secondary dark:hover:bg-rex-bg-secondary-dark"
        >
          {advanced ? 'Simple' : 'Advanced'}
        </button>
      </div>

      {/* Operation summaries */}
      {data.operations.length > 0 && data.operations.some(op => op.decoded_summary) && (
        <div className="bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark rounded-lg p-4 mb-6 border border-rex-border dark:border-rex-border-dark">
          {data.operations.filter(op => op.decoded_summary).map((op, i) => (
            <p key={i} className="text-lg text-rex-text dark:text-rex-text-dark">
              {op.decoded_summary}
            </p>
          ))}
        </div>
      )}

      {/* Transaction details */}
      <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mb-6">
        <dl className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Status</dt>
            <dd className="mt-1">
              <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                tx.status === true ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' :
                tx.status === false ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' :
                'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
              }`}>
                {tx.status === true ? 'Success' : tx.status === false ? 'Failed' : 'Pending'}
              </span>
            </dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Block</dt>
            <dd className="mt-1">{tx.block_number?.toLocaleString()}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Hash</dt>
            <dd className="font-mono mt-1 break-all text-xs">{hash}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">From</dt>
            <dd className="font-mono mt-1 break-all text-xs">{tx.from_address}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">To</dt>
            <dd className="font-mono mt-1 break-all text-xs">{tx.to_address ?? 'Contract Creation'}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Value</dt>
            <dd className="font-mono mt-1">{formatAmount(tx.value, 18, 'ETH')}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Gas Used</dt>
            <dd className="font-mono mt-1">{tx.gas_used ? formatGas(tx.gas_used) : '-'}</dd>
          </div>
        </dl>
      </div>

      {/* Operations */}
      {data.operations.length > 0 && (
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mb-6">
          <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Operations</h2>
          <div className="space-y-2">
            {data.operations.map(op => (
              <div key={op.operation_index} className="text-sm p-3 bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark rounded">
                <div className="flex items-center gap-2 mb-1">
                  <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark font-mono">
                    {op.operation_type}
                  </span>
                  <span className="text-rex-text-secondary dark:text-rex-text-secondary-dark">#{op.operation_index}</span>
                </div>
                {op.decoded_summary && (
                  <p className="text-rex-text dark:text-rex-text-dark">{op.decoded_summary}</p>
                )}
                {advanced && (
                  <div className="mt-2 text-xs font-mono text-rex-text-secondary dark:text-rex-text-secondary-dark">
                    <div>From: {op.from_address}</div>
                    <div>To: {op.to_address}</div>
                    <div>Value: {op.value}</div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Token Transfers */}
      {data.token_transfers.length > 0 && (
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mb-6">
          <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Token Transfers</h2>
          <div className="space-y-2 text-sm">
            {data.token_transfers.map((t, i) => (
              <div key={i} className="flex items-center gap-2 font-mono text-xs">
                <span className="text-rex-text-secondary dark:text-rex-text-secondary-dark">{t.from_address.slice(0, 10)}...</span>
                <span>→</span>
                <span className="text-rex-text-secondary dark:text-rex-text-secondary-dark">{t.to_address.slice(0, 10)}...</span>
                <span className="ml-auto font-semibold">{t.amount} ({t.token_type})</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Logs (advanced only) */}
      {advanced && data.logs.length > 0 && (
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
          <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Event Logs ({data.logs.length})</h2>
          <div className="space-y-3">
            {data.logs.map(log => (
              <div key={log.log_index} className="text-xs font-mono p-3 bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark rounded">
                <div className="text-rex-text-secondary dark:text-rex-text-secondary-dark mb-1">Log #{log.log_index} — {log.contract_address}</div>
                {log.topic0 && <div className="truncate">topic0: {log.topic0}</div>}
                {log.topic1 && <div className="truncate">topic1: {log.topic1}</div>}
                {log.topic2 && <div className="truncate">topic2: {log.topic2}</div>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Cross-chain links */}
      {data.cross_chain_links.length > 0 && (
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mt-6">
          <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Cross-Chain Journey</h2>
          {data.cross_chain_links.map((link, i) => (
            <div key={i} className="text-sm p-3 bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark rounded">
              <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark mr-2">{link.link_type}</span>
              <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark">{link.status}</span>
              <div className="mt-2 text-xs font-mono text-rex-text-secondary dark:text-rex-text-secondary-dark">
                Chain {link.source_chain_id} → Chain {link.destination_chain_id}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
