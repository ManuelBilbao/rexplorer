import { Link, useParams } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useBlock, useTransactions } from '../api/queries'
import { formatBlockNumber, formatGas, formatTimestamp } from '../lib/format'

export function BlockDetailPage() {
  const chain = useChain()
  const { number } = useParams()
  const { data: block, isLoading } = useBlock(chain, number)
  const { data: txData } = useTransactions(chain, { beforeBlock: number ? Number(number) + 1 : undefined })

  if (isLoading) {
    return <div className="space-y-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="h-6 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse" />
      ))}
    </div>
  }

  if (!block) return <div className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Block not found</div>

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-rex-text dark:text-rex-text-dark">
        Block {formatBlockNumber(block.block_number)}
      </h1>

      <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mb-6">
        <dl className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Block Number</dt>
            <dd className="font-mono mt-1">{formatBlockNumber(block.block_number)}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Timestamp</dt>
            <dd className="mt-1">{formatTimestamp(block.timestamp)}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Hash</dt>
            <dd className="font-mono mt-1 break-all">{block.hash}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Parent Hash</dt>
            <dd className="font-mono mt-1 break-all">{block.parent_hash}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Gas Used</dt>
            <dd className="font-mono mt-1">{formatGas(block.gas_used)} / {formatGas(block.gas_limit)}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Transactions</dt>
            <dd className="mt-1">{block.transaction_count}</dd>
          </div>
          {block.base_fee_per_gas && (
            <div>
              <dt className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Base Fee</dt>
              <dd className="font-mono mt-1">{formatGas(block.base_fee_per_gas)} wei</dd>
            </div>
          )}
        </dl>
      </div>

      {txData && txData.data.length > 0 && (
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg overflow-hidden">
          <h2 className="text-lg font-semibold p-4 text-rex-text dark:text-rex-text-dark">Transactions</h2>
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark border-y border-rex-border dark:border-rex-border-dark">
                <th className="px-4 py-2 text-left font-medium text-rex-text-secondary dark:text-rex-text-secondary-dark">Hash</th>
                <th className="px-4 py-2 text-left font-medium text-rex-text-secondary dark:text-rex-text-secondary-dark">From</th>
                <th className="px-4 py-2 text-left font-medium text-rex-text-secondary dark:text-rex-text-secondary-dark">To</th>
                <th className="px-4 py-2 text-right font-medium text-rex-text-secondary dark:text-rex-text-secondary-dark">Value</th>
              </tr>
            </thead>
            <tbody>
              {txData.data.map(tx => (
                <tr key={tx.hash} className="border-b border-rex-border dark:border-rex-border-dark">
                  <td className="px-4 py-2">
                    <Link to={`/${chain}/tx/${tx.hash}`} className="text-rex-primary hover:underline font-mono">
                      {tx.hash.slice(0, 10)}...
                    </Link>
                  </td>
                  <td className="px-4 py-2 font-mono text-xs">{tx.from_address.slice(0, 10)}...</td>
                  <td className="px-4 py-2 font-mono text-xs">{tx.to_address?.slice(0, 10) ?? 'Contract Creation'}...</td>
                  <td className="px-4 py-2 text-right font-mono">{tx.value === '0' ? '0' : tx.value}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
