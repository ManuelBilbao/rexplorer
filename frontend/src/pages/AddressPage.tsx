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
        <div key={i} className="h-6 bg-rex-bg-tertiary rounded animate-pulse" />
      ))}
    </div>
  }

  if (!data) return <div className="text-rex-text-secondary">Address not found</div>

  const { address } = data

  return (
    <div>
      <h1 className="text-2xl font-bold mb-2 text-rex-text">
        Address
        {address.is_contract && (
          <span className="ml-2 text-sm px-2 py-0.5 rounded bg-rex-primary/10 text-rex-primary font-normal">
            Contract
          </span>
        )}
      </h1>
      <p className="font-mono text-sm text-rex-text-secondary break-all mb-6">{hash}</p>
      {address.label && (
        <p className="text-lg mb-6 text-rex-text">{address.label}</p>
      )}

      {/* Recent Transactions */}
      <div className="border border-rex-border rounded-lg p-4 mb-6">
        <h2 className="text-lg font-semibold mb-3 text-rex-text">Recent Transactions</h2>
        {data.recent_transactions.length === 0 ? (
          <p className="text-sm text-rex-text-secondary">No transactions found</p>
        ) : (
          <div className="space-y-2 text-sm">
            {data.recent_transactions.map(tx => (
              <div key={tx.hash} className="flex items-center justify-between">
                <Link to={`/${chain}/tx/${tx.hash}`} className="text-rex-primary hover:underline font-mono">
                  {tx.hash.slice(0, 10)}...{tx.hash.slice(-6)}
                </Link>
                <div className="text-rex-text-secondary text-xs font-mono">
                  <Link to={`/${chain}/address/${tx.from_address}`} className="hover:text-rex-primary">{tx.from_address.slice(0, 8)}...</Link>
                  {' → '}
                  {tx.to_address ? (
                    <Link to={`/${chain}/address/${tx.to_address}`} className="hover:text-rex-primary">{tx.to_address.slice(0, 8)}...</Link>
                  ) : 'Create'}
                </div>
                <span className={`px-2 py-0.5 text-xs rounded ${
                  tx.status === true ? 'bg-rex-success/10 text-rex-success' :
                  tx.status === false ? 'bg-rex-danger/10 text-rex-danger' :
                  'bg-rex-bg-tertiary text-rex-text-secondary'
                }`}>
                  {tx.status === true ? 'OK' : tx.status === false ? 'Fail' : '...'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Recent Token Transfers */}
      <div className="border border-rex-border rounded-lg p-4">
        <h2 className="text-lg font-semibold mb-3 text-rex-text">Recent Token Transfers</h2>
        {data.recent_token_transfers.length === 0 ? (
          <p className="text-sm text-rex-text-secondary">No token transfers found</p>
        ) : (
          <div className="space-y-2 text-sm">
            {data.recent_token_transfers.map((t, i) => (
              <div key={i} className="flex items-center gap-2 font-mono text-xs">
                <span>{t.from_address.slice(0, 10)}...</span>
                <span>→</span>
                <span>{t.to_address.slice(0, 10)}...</span>
                <span className="ml-auto">{formatTransferAmount(t)} {t.token_type === 'native' ? nativeSymbol(chain) : t.token_type.toUpperCase()}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

function formatTransferAmount(t: { amount: string; token_type: string }): string {
  if (t.token_type === 'native') {
    try {
      const num = BigInt(t.amount)
      const divisor = BigInt(10 ** 18)
      const whole = num / divisor
      const remainder = num % divisor
      if (remainder === 0n) return whole.toLocaleString()
      const fracStr = remainder.toString().padStart(18, '0').replace(/0+$/, '').slice(0, 6)
      return `${whole.toLocaleString()}.${fracStr}`
    } catch { return t.amount }
  }
  return t.amount
}

const NATIVE_SYMBOLS: Record<string, string> = {
  ethereum: 'ETH', optimism: 'ETH', base: 'ETH', bnb: 'BNB', polygon: 'POL',
}

function nativeSymbol(chain: string | null): string {
  return NATIVE_SYMBOLS[chain || ''] || 'ETH'
}
