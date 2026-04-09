import { Link } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useHomeData } from '../api/queries'
import { formatBlockNumber } from '../lib/format'
import Skeleton from '../components/ui/Skeleton'
import { BlockNumber } from '../components/explorer/BlockNumber'
import { TimeAgo } from '../components/explorer/TimeAgo'

export function HomePage() {
  const chain = useChain()
  const { data, isLoading } = useHomeData(chain)

  if (isLoading || !data) {
    return <LoadingSkeleton />
  }

  const latestBlock = data.latest_blocks[0]

  return (
    <div>
      {/* Network Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard
          label="Block Height"
          value={latestBlock ? formatBlockNumber(latestBlock.block_number) : '-'}
          sub={latestBlock ? <TimeAgo timestamp={latestBlock.timestamp} /> : null}
        />
        <StatCard
          label="Transactions"
          value={latestBlock ? `${latestBlock.transaction_count} in last block` : '-'}
          sub={null}
        />
        <StatCard
          label="Gas Used"
          value={latestBlock ? `${Math.round((latestBlock.gas_used / latestBlock.gas_limit) * 100)}%` : '-'}
          sub={latestBlock ? `${(latestBlock.gas_used / 1e6).toFixed(1)}M / ${(latestBlock.gas_limit / 1e6).toFixed(1)}M` : null}
        />
        <StatCard
          label="Chain"
          value={data.chain.name}
          sub={data.chain.explorer_slug}
        />
      </div>

      {/* Two column: Blocks + Activity */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Latest Blocks */}
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl p-5">
          <h2 className="text-sm font-semibold mb-4 text-rex-text-secondary uppercase tracking-wide">
            Latest Blocks
          </h2>
          <div className="space-y-1">
            {data.latest_blocks.map(block => (
              <div key={block.block_number} className="flex items-center justify-between py-2.5 border-b border-rex-border last:border-0">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-2 rounded-full bg-rex-success" />
                  <BlockNumber number={block.block_number} chain={chain!} />
                </div>
                <div className="flex items-center gap-4 text-xs">
                  <span className="text-rex-text-secondary">
                    {block.transaction_count} txs
                  </span>
                  <GasBar percent={Math.round((block.gas_used / (block.gas_limit || 1)) * 100)} />
                  <span className="w-12 text-right">
                    <TimeAgo timestamp={block.timestamp} />
                  </span>
                </div>
              </div>
            ))}
          </div>
          <Link
            to={`/${chain}/blocks`}
            className="block text-center text-xs text-rex-primary hover:underline mt-4"
          >
            View all blocks →
          </Link>
        </div>

        {/* Recent Activity (decoded operations) */}
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl p-5">
          <h2 className="text-sm font-semibold mb-4 text-rex-text-secondary uppercase tracking-wide">
            Recent Activity
          </h2>
          <div className="space-y-1">
            {data.latest_transactions.slice(0, 8).map(tx => (
              <div key={tx.hash} className="flex items-center justify-between py-2.5 border-b border-rex-border last:border-0">
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <TxTypeIcon status={tx.status} />
                  <Link
                    to={`/${chain}/tx/${tx.hash}`}
                    className="text-rex-primary font-mono text-xs hover:underline truncate"
                  >
                    {tx.hash.slice(0, 10)}...{tx.hash.slice(-6)}
                  </Link>
                </div>
                <div className="text-xs text-rex-text-secondary text-right shrink-0 ml-3 font-mono">
                  <Link to={`/${chain}/address/${tx.from_address}`} className="hover:text-rex-primary">{tx.from_address.slice(0, 6)}...</Link>
                  {' → '}
                  {tx.to_address ? (
                    <Link to={`/${chain}/address/${tx.to_address}`} className="hover:text-rex-primary">{tx.to_address.slice(0, 6)}...</Link>
                  ) : 'Create'}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ label, value, sub }: { label: string; value: string; sub: React.ReactNode }) {
  return (
    <div className="bg-rex-bg-secondary border border-rex-border rounded-xl p-4">
      <div className="text-xs text-rex-text-secondary uppercase tracking-wide mb-2">
        {label}
      </div>
      <div className="text-xl font-bold text-rex-text">
        {value}
      </div>
      {sub && (
        <div className="text-xs text-rex-text-secondary mt-1">
          {sub}
        </div>
      )}
    </div>
  )
}

function GasBar({ percent }: { percent: number }) {
  const color =
    percent > 90 ? 'bg-rex-danger' :
    percent > 70 ? 'bg-rex-warning' :
    'bg-rex-success'

  return (
    <div className="w-12 h-1 rounded-full bg-rex-bg-tertiary">
      <div className={`h-full rounded-full ${color}`} style={{ width: `${percent}%` }} />
    </div>
  )
}

function TxTypeIcon({ status }: { status: boolean | null }) {
  if (status === true) return <div className="w-2 h-2 rounded-full bg-rex-success" />
  if (status === false) return <div className="w-2 h-2 rounded-full bg-rex-danger" />
  return <div className="w-2 h-2 rounded-full bg-rex-text-secondary" />
}

function LoadingSkeleton() {
  return (
    <div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="bg-rex-bg-secondary border border-rex-border rounded-xl p-4">
            <Skeleton width="4rem" height="0.75rem" />
            <div className="mt-3">
              <Skeleton width="6rem" height="1.5rem" />
            </div>
          </div>
        ))}
      </div>
      <div className="grid md:grid-cols-2 gap-6">
        {[1, 2].map(i => (
          <div key={i} className="bg-rex-bg-secondary border border-rex-border rounded-xl p-5">
            <Skeleton width="8rem" height="1rem" />
            <div className="mt-4 space-y-3">
              {[1, 2, 3, 4, 5].map(j => (
                <Skeleton key={j} width="100%" height="1.25rem" />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
