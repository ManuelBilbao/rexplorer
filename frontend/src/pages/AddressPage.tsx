/**
 * AddressPage — comprehensive address overview.
 *
 * Data flow:
 * ```mermaid
 * sequenceDiagram
 *   participant UI as AddressPage
 *   participant BFF as BFF API
 *   participant API as Public API
 *   UI->>BFF: GET /internal/.../addresses/:hash (overview)
 *   UI->>BFF: GET /internal/.../addresses/:hash/balance-history
 *   Note over UI: User clicks "Load more"
 *   UI->>API: GET /api/v1/.../transactions?address=...&before_block=...
 *   UI->>API: GET /api/v1/.../addresses/:hash/token-transfers?before=...
 * ```
 */

import { useState } from 'react'
import { Link, useParams } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useAddressOverview, useBalanceHistory, useTransactions, useAddressTokenTransfers } from '../api/queries'
import { BalanceChart } from '../components/explorer/BalanceChart'
import { Tabs, TabList, Tab, TabPanel } from '../components/ui/Tabs'
import { timeAgo } from '../lib/format'

export function AddressPage() {
  const chain = useChain()
  const { hash } = useParams()
  const { data, isLoading } = useAddressOverview(chain, hash)
  const { data: historyData, isLoading: historyLoading } = useBalanceHistory(chain, hash)

  if (isLoading) {
    return (
      <div className="space-y-4">
        {/* Stat card skeletons */}
        <div className="grid grid-cols-3 gap-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-20 bg-rex-bg-tertiary rounded-lg animate-pulse" />
          ))}
        </div>
        {/* Chart skeleton */}
        <div className="h-64 bg-rex-bg-tertiary rounded-lg animate-pulse" />
        {/* List skeleton */}
        <div className="h-48 bg-rex-bg-tertiary rounded-lg animate-pulse" />
      </div>
    )
  }

  if (!data) return <div className="text-rex-text-secondary">Address not found</div>

  const { address } = data
  const lastTx = data.recent_transactions[0]
  const lastActive = lastTx?.block_number
    ? timeAgo(lastTx.chain_extra?.timestamp as string || address.first_seen_at)
    : null

  return (
    <div>
      {/* Header */}
      <h1 className="text-2xl font-bold mb-1 text-rex-text">
        Address
        {address.is_contract && (
          <span className="ml-2 text-sm px-2 py-0.5 rounded bg-rex-primary/10 text-rex-primary font-normal">
            Contract
          </span>
        )}
      </h1>
      <p className="font-mono text-sm text-rex-text-secondary break-all mb-2">{hash}</p>
      {address.label && (
        <p className="text-base mb-4 text-rex-text">{address.label}</p>
      )}

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard label="Balance" value={formatBalance(address.balance_wei, chain)} />
        <StatCard label="Last Active" value={lastActive || timeAgo(address.first_seen_at)} />
        <StatCard label="First Seen" value={timeAgo(address.first_seen_at)} />
      </div>

      {/* Balance Chart */}
      <div className="mb-6">
        {historyLoading ? (
          <div className="h-64 bg-rex-bg-tertiary rounded-lg animate-pulse" />
        ) : (
          <BalanceChart data={historyData?.data || []} />
        )}
      </div>

      {/* Tabbed Transactions / Token Transfers */}
      <Tabs>
        <TabList>
          <Tab>Transactions</Tab>
          <Tab>Token Transfers</Tab>
        </TabList>

        <TabPanel index={0}>
          <TransactionsList
            chain={chain}
            hash={hash!}
            initialTxs={data.recent_transactions}
          />
        </TabPanel>

        <TabPanel index={1}>
          <TokenTransfersList
            chain={chain}
            hash={hash!}
            initialTransfers={data.recent_token_transfers}
          />
        </TabPanel>
      </Tabs>
    </div>
  )
}

/* ── Stat Card ── */

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="border border-rex-border rounded-lg p-4">
      <div className="text-xs text-rex-text-secondary mb-1">{label}</div>
      <div className="text-lg font-semibold text-rex-text truncate">{value}</div>
    </div>
  )
}

/* ── Transactions List with pagination ── */

interface TxListProps {
  chain: string | null
  hash: string
  initialTxs: Array<{
    hash: string
    from_address: string
    to_address: string | null
    value: string
    status: boolean | null
    block_number: number | null
  }>
}

function TransactionsList({ chain, hash, initialTxs }: TxListProps) {
  const [cursor, setCursor] = useState<number | undefined>(undefined)
  const [allTxs, setAllTxs] = useState(initialTxs)
  const { data: moreTxs, isFetching } = useTransactions(chain, cursor ? { address: hash, beforeBlock: cursor } : undefined)

  const loadMore = () => {
    const lastTx = allTxs[allTxs.length - 1]
    if (lastTx?.block_number) {
      setCursor(lastTx.block_number)
    }
  }

  // Append paginated results when they arrive
  if (moreTxs?.data && moreTxs.data.length > 0 && cursor) {
    const newHashes = new Set(moreTxs.data.map(t => t.hash))
    const existingHashes = new Set(allTxs.map(t => t.hash))
    const genuinelyNew = moreTxs.data.filter(t => !existingHashes.has(t.hash))
    if (genuinelyNew.length > 0) {
      setAllTxs(prev => [...prev, ...genuinelyNew])
      setCursor(undefined) // reset so we don't re-fetch
    }
  }

  if (allTxs.length === 0) {
    return <p className="text-sm text-rex-text-secondary">No transactions found</p>
  }

  return (
    <div>
      <div className="space-y-2 text-sm">
        {allTxs.map(tx => (
          <div key={tx.hash} className="flex items-center justify-between gap-2">
            <Link to={`/${chain}/tx/${tx.hash}`} className="text-rex-primary hover:underline font-mono shrink-0">
              {tx.hash.slice(0, 10)}...{tx.hash.slice(-6)}
            </Link>
            <div className="text-rex-text-secondary text-xs font-mono truncate">
              <Link to={`/${chain}/address/${tx.from_address}`} className="hover:text-rex-primary">{tx.from_address.slice(0, 8)}...</Link>
              {' \u2192 '}
              {tx.to_address ? (
                <Link to={`/${chain}/address/${tx.to_address}`} className="hover:text-rex-primary">{tx.to_address.slice(0, 8)}...</Link>
              ) : 'Create'}
            </div>
            <span className={`px-2 py-0.5 text-xs rounded shrink-0 ${
              tx.status === true ? 'bg-rex-success/10 text-rex-success' :
              tx.status === false ? 'bg-rex-danger/10 text-rex-danger' :
              'bg-rex-bg-tertiary text-rex-text-secondary'
            }`}>
              {tx.status === true ? 'OK' : tx.status === false ? 'Fail' : '...'}
            </span>
          </div>
        ))}
      </div>

      {initialTxs.length >= 25 && (
        <div className="mt-4 text-center">
          <button
            onClick={loadMore}
            disabled={isFetching}
            className="px-4 py-2 text-sm border border-rex-border rounded-lg text-rex-text hover:bg-rex-bg-secondary transition-colors disabled:opacity-50"
          >
            {isFetching ? 'Loading...' : 'Load more'}
          </button>
        </div>
      )}
    </div>
  )
}

/* ── Token Transfers List with pagination ── */

interface TransferListProps {
  chain: string | null
  hash: string
  initialTransfers: Array<{
    from_address: string
    to_address: string
    token_contract_address: string
    amount: string
    token_type: string
  }>
}

function TokenTransfersList({ chain, hash, initialTransfers }: TransferListProps) {
  const [cursor, setCursor] = useState<number | undefined>(undefined)
  const [allTransfers, setAllTransfers] = useState(initialTransfers)
  const { data: moreTransfers, isFetching } = useAddressTokenTransfers(chain, hash, cursor)

  const loadMore = () => {
    // Token transfers use ID-based cursor; we need the next_cursor from the API
    // For initial load, trigger the first paginated fetch
    if (!cursor) {
      setCursor(-1) // triggers the query with no cursor (gets first page from API)
    }
  }

  // Append paginated results
  if (moreTransfers?.data && moreTransfers.data.length > 0 && cursor) {
    const genuinelyNew = moreTransfers.data.filter(
      t => !allTransfers.some(e => e.from_address === t.from_address && e.to_address === t.to_address && e.amount === t.amount)
    )
    if (genuinelyNew.length > 0) {
      setAllTransfers(prev => [...prev, ...genuinelyNew])
      setCursor(undefined)
    }
  }

  if (allTransfers.length === 0) {
    return <p className="text-sm text-rex-text-secondary">No token transfers found</p>
  }

  return (
    <div>
      <div className="space-y-2 text-sm">
        {allTransfers.map((t, i) => (
          <div key={i} className="flex items-center gap-2 font-mono text-xs">
            <Link to={`/${chain}/address/${t.from_address}`} className="hover:text-rex-primary text-rex-text-secondary">
              {t.from_address.slice(0, 10)}...
            </Link>
            <span className="text-rex-text-secondary">{'\u2192'}</span>
            <Link to={`/${chain}/address/${t.to_address}`} className="hover:text-rex-primary text-rex-text-secondary">
              {t.to_address.slice(0, 10)}...
            </Link>
            <span className="ml-auto text-rex-text">
              {formatTransferAmount(t)} {t.token_type === 'native' ? nativeSymbol(chain) : t.token_type.toUpperCase()}
            </span>
          </div>
        ))}
      </div>

      {initialTransfers.length >= 25 && (
        <div className="mt-4 text-center">
          <button
            onClick={loadMore}
            disabled={isFetching}
            className="px-4 py-2 text-sm border border-rex-border rounded-lg text-rex-text hover:bg-rex-bg-secondary transition-colors disabled:opacity-50"
          >
            {isFetching ? 'Loading...' : 'Load more'}
          </button>
        </div>
      )}
    </div>
  )
}

/* ── Formatting helpers ── */

function formatBalance(balanceWei: string | null, chain: string | null): string {
  if (!balanceWei) return '\u2014'
  try {
    const num = BigInt(balanceWei)
    const divisor = BigInt(10 ** 18)
    const whole = num / divisor
    const remainder = num % divisor
    let formatted: string
    if (remainder === 0n) {
      formatted = whole.toLocaleString()
    } else {
      const fracStr = remainder.toString().padStart(18, '0').replace(/0+$/, '').slice(0, 6)
      formatted = `${whole.toLocaleString()}.${fracStr}`
    }
    return `${formatted} ${nativeSymbol(chain)}`
  } catch {
    return '\u2014'
  }
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
