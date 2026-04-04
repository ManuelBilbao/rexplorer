import { Link, useParams } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useAddressOverview } from '../api/queries'

export function AddressPage() {
  const chain = useChain()
  const { hash } = useParams()
  const { data, isLoading } = useAddressOverview(chain, hash)

  if (isLoading) {
    return <div className="space-y-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="h-6 bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark rounded animate-pulse" />
      ))}
    </div>
  }

  if (!data) return <div className="text-rex-text-secondary dark:text-rex-text-secondary-dark">Address not found</div>

  const { address } = data

  return (
    <div>
      <h1 className="text-2xl font-bold mb-2 text-rex-text dark:text-rex-text-dark">
        Address
        {address.is_contract && (
          <span className="ml-2 text-sm px-2 py-0.5 rounded bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 font-normal">
            Contract
          </span>
        )}
      </h1>
      <p className="font-mono text-sm text-rex-text-secondary dark:text-rex-text-secondary-dark break-all mb-6">{hash}</p>
      {address.label && (
        <p className="text-lg mb-6 text-rex-text dark:text-rex-text-dark">{address.label}</p>
      )}

      {/* Recent Transactions */}
      <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4 mb-6">
        <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Recent Transactions</h2>
        {data.recent_transactions.length === 0 ? (
          <p className="text-sm text-rex-text-secondary dark:text-rex-text-secondary-dark">No transactions found</p>
        ) : (
          <div className="space-y-2 text-sm">
            {data.recent_transactions.map(tx => (
              <div key={tx.hash} className="flex items-center justify-between">
                <Link to={`/${chain}/tx/${tx.hash}`} className="text-rex-primary hover:underline font-mono">
                  {tx.hash.slice(0, 10)}...{tx.hash.slice(-6)}
                </Link>
                <div className="text-rex-text-secondary dark:text-rex-text-secondary-dark">
                  {tx.from_address.slice(0, 8)}... → {tx.to_address?.slice(0, 8) ?? 'Create'}...
                </div>
                <span className={`px-2 py-0.5 text-xs rounded ${
                  tx.status === true ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' :
                  tx.status === false ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' :
                  'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
                }`}>
                  {tx.status === true ? 'OK' : tx.status === false ? 'Fail' : '...'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Recent Token Transfers */}
      <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
        <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Recent Token Transfers</h2>
        {data.recent_token_transfers.length === 0 ? (
          <p className="text-sm text-rex-text-secondary dark:text-rex-text-secondary-dark">No token transfers found</p>
        ) : (
          <div className="space-y-2 text-sm">
            {data.recent_token_transfers.map((t, i) => (
              <div key={i} className="flex items-center gap-2 font-mono text-xs">
                <span>{t.from_address.slice(0, 10)}...</span>
                <span>→</span>
                <span>{t.to_address.slice(0, 10)}...</span>
                <span className="ml-auto">{t.amount} ({t.token_type})</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
