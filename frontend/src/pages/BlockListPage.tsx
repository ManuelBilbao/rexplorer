import { useState } from 'react'
import { Link } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useBlocks } from '../api/queries'
import { formatBlockNumber, formatGas, timeAgo } from '../lib/format'

export function BlockListPage() {
  const chain = useChain()
  const [cursor, setCursor] = useState<number | undefined>()
  const { data, isLoading } = useBlocks(chain, cursor)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-rex-text">Blocks</h1>

      <div className="border border-rex-border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-rex-bg-secondary border-b border-rex-border">
              <th className="px-4 py-3 text-left font-medium text-rex-text-secondary">Block</th>
              <th className="px-4 py-3 text-left font-medium text-rex-text-secondary">Age</th>
              <th className="px-4 py-3 text-right font-medium text-rex-text-secondary">Txs</th>
              <th className="px-4 py-3 text-right font-medium text-rex-text-secondary">Gas Used</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              Array.from({ length: 10 }).map((_, i) => (
                <tr key={i} className="border-b border-rex-border">
                  {[1, 2, 3, 4].map(j => (
                    <td key={j} className="px-4 py-3">
                      <div className="h-4 bg-rex-bg-tertiary rounded animate-pulse" />
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              data?.data.map(block => (
                <tr key={block.block_number} className="border-b border-rex-border hover:bg-rex-bg-secondary dark:hover:bg-rex-bg-secondary-dark">
                  <td className="px-4 py-3">
                    <Link to={`/${chain}/block/${block.block_number}`} className="text-rex-primary hover:underline font-mono">
                      {formatBlockNumber(block.block_number)}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-rex-text-secondary">{timeAgo(block.timestamp)}</td>
                  <td className="px-4 py-3 text-right">{block.transaction_count}</td>
                  <td className="px-4 py-3 text-right font-mono text-rex-text-secondary">{formatGas(block.gas_used)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        {data?.next_cursor != null && (
          <div className="p-4 text-center border-t border-rex-border">
            <button
              onClick={() => setCursor(Number(data.next_cursor))}
              className="px-4 py-2 text-sm text-rex-primary hover:underline"
            >
              Load more
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
