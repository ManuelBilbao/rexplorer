import { Link } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useHomeData } from '../api/queries'
import { formatBlockNumber, timeAgo } from '../lib/format'

export function HomePage() {
  const chain = useChain()
  const { data, isLoading } = useHomeData(chain)

  if (isLoading || !data) {
    return <LoadingSkeleton />
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-rex-text dark:text-rex-text-dark">
        {data.chain.name}
      </h1>

      <div className="grid md:grid-cols-2 gap-6">
        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
          <h2 className="text-lg font-semibold mb-4 text-rex-text dark:text-rex-text-dark">
            Latest Blocks
          </h2>
          <div className="space-y-3">
            {data.latest_blocks.map(block => (
              <div key={block.block_number} className="flex items-center justify-between text-sm">
                <Link
                  to={`/${chain}/block/${block.block_number}`}
                  className="text-rex-primary hover:underline font-mono"
                >
                  {formatBlockNumber(block.block_number)}
                </Link>
                <span className="text-rex-text-secondary dark:text-rex-text-secondary-dark">
                  {block.transaction_count} txs &middot; {timeAgo(block.timestamp)}
                </span>
              </div>
            ))}
          </div>
          <Link
            to={`/${chain}/blocks`}
            className="block text-center text-sm text-rex-primary hover:underline mt-4"
          >
            View all blocks
          </Link>
        </div>

        <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
          <h2 className="text-lg font-semibold mb-4 text-rex-text dark:text-rex-text-dark">
            Latest Transactions
          </h2>
          <div className="space-y-3">
            {data.latest_transactions.map(tx => (
              <div key={tx.hash} className="flex items-center justify-between text-sm">
                <Link
                  to={`/${chain}/tx/${tx.hash}`}
                  className="text-rex-primary hover:underline font-mono"
                >
                  {tx.hash.slice(0, 10)}...{tx.hash.slice(-6)}
                </Link>
                <span className="text-rex-text-secondary dark:text-rex-text-secondary-dark">
                  {tx.from_address.slice(0, 8)}... → {tx.to_address?.slice(0, 8) ?? 'Contract'}...
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function LoadingSkeleton() {
  return (
    <div>
      <div className="h-8 w-48 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse mb-6" />
      <div className="grid md:grid-cols-2 gap-6">
        {[1, 2].map(i => (
          <div key={i} className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
            <div className="h-6 w-32 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse mb-4" />
            {[1, 2, 3, 4, 5].map(j => (
              <div key={j} className="h-5 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse mb-3" />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}
