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
import { useAddressOverview, useBalanceHistory, useTransactions, useAddressTokenTransfers, useAddressInternalTransactions } from '../api/queries'
import { BalanceChart } from '../components/explorer/BalanceChart'
import { Tabs, TabList, Tab, TabPanel } from '../components/ui/Tabs'
import Skeleton from '../components/ui/Skeleton'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import { StatusBadge } from '../components/explorer/StatusBadge'
import { AddressDisplay } from '../components/explorer/AddressDisplay'
import { TxHash } from '../components/explorer/TxHash'
import { TimeAgo } from '../components/explorer/TimeAgo'

export function AddressPage() {
  const chain = useChain()
  const { hash } = useParams()
  const { data, isLoading } = useAddressOverview(chain, hash)
  const { data: historyData, isLoading: historyLoading } = useBalanceHistory(chain, hash)

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="grid grid-cols-3 gap-4">
          {[1, 2, 3].map(i => (
            <Skeleton key={i} width="100%" height="5rem" />
          ))}
        </div>
        <Skeleton width="100%" height="16rem" />
        <Skeleton width="100%" height="12rem" />
      </div>
    )
  }

  if (!data) return <div className="text-rex-text-secondary">Address not found</div>

  const { address } = data
  const lastTx = data.recent_transactions[0]
  const lastActive = lastTx?.block_number
    ? lastTx.chain_extra?.timestamp as string || address.first_seen_at
    : null

  return (
    <div>
      {/* Header */}
      <h1 className="text-2xl font-bold mb-1 text-rex-text">
        Address
        {address.is_contract && (
          <span className="ml-2 align-middle">
            <Badge variant="blue">Contract</Badge>
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
        <StatCard label="Last Active" value={lastActive ? <TimeAgo timestamp={lastActive} /> : <TimeAgo timestamp={address.first_seen_at} />} />
        <StatCard label="First Seen" value={<TimeAgo timestamp={address.first_seen_at} />} />
      </div>

      {/* Balance Chart */}
      <div className="mb-6">
        {historyLoading ? (
          <Skeleton width="100%" height="16rem" />
        ) : (
          <BalanceChart data={historyData?.data || []} />
        )}
      </div>

      {/* Tabbed Transactions / Internal Txns / Token Transfers */}
      <Tabs>
        <TabList>
          <Tab>Transactions</Tab>
          <Tab>Internal Txns</Tab>
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
          <InternalTransactionsList chain={chain} hash={hash!} />
        </TabPanel>

        <TabPanel index={2}>
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

function StatCard({ label, value }: { label: string; value: React.ReactNode }) {
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
    const existingHashes = new Set(allTxs.map(t => t.hash))
    const genuinelyNew = moreTxs.data.filter(t => !existingHashes.has(t.hash))
    if (genuinelyNew.length > 0) {
      setAllTxs(prev => [...prev, ...genuinelyNew])
      setCursor(undefined)
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
            <TxHash hash={tx.hash} chain={chain!} />
            <div className="text-rex-text-secondary text-xs font-mono truncate">
              <AddressDisplay address={tx.from_address} chain={chain!} />
              {' → '}
              {tx.to_address ? (
                <AddressDisplay address={tx.to_address} chain={chain!} />
              ) : 'Create'}
            </div>
            <StatusBadge status={tx.status} />
          </div>
        ))}
      </div>

      {initialTxs.length >= 25 && (
        <div className="mt-4 text-center">
          <Button
            variant="outline"
            size="sm"
            onClick={loadMore}
            loading={isFetching}
          >
            Load more
          </Button>
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
    if (!cursor) {
      setCursor(-1)
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
          <div key={i} className="flex items-center gap-2 text-xs">
            <AddressDisplay address={t.from_address} chain={chain!} />
            <span className="text-rex-text-secondary">→</span>
            <AddressDisplay address={t.to_address} chain={chain!} />
            <span className="ml-auto font-mono text-rex-text">
              {formatTransferAmount(t)} {t.token_type === 'native' ? nativeSymbol(chain) : t.token_type.toUpperCase()}
            </span>
          </div>
        ))}
      </div>

      {initialTransfers.length >= 25 && (
        <div className="mt-4 text-center">
          <Button
            variant="outline"
            size="sm"
            onClick={loadMore}
            loading={isFetching}
          >
            Load more
          </Button>
        </div>
      )}
    </div>
  )
}

/* ── Internal Transactions List ── */

function InternalTransactionsList({ chain, hash }: { chain: string | null; hash: string }) {
  const [cursor, setCursor] = useState<number | undefined>(undefined)
  const { data, isFetching } = useAddressInternalTransactions(chain, hash, cursor)

  const entries = data?.data || []
  const [allEntries, setAllEntries] = useState<typeof entries>([])

  // Initialize or append
  if (entries.length > 0 && !cursor && allEntries.length === 0) {
    setAllEntries(entries)
  }

  if (entries.length > 0 && cursor) {
    const newEntries = entries.filter(
      e => !allEntries.some(a => a.transaction_hash === e.transaction_hash && a.trace_index === e.trace_index)
    )
    if (newEntries.length > 0) {
      setAllEntries(prev => [...prev, ...newEntries])
      setCursor(undefined)
    }
  }

  if (!isFetching && allEntries.length === 0 && entries.length === 0) {
    return <p className="text-sm text-rex-text-secondary">No internal transactions found</p>
  }

  const displayEntries = allEntries.length > 0 ? allEntries : entries

  return (
    <div>
      <div className="space-y-2 text-sm">
        {displayEntries.map((entry) => (
          <div key={`${entry.transaction_hash}-${entry.trace_index}`} className="flex items-center justify-between gap-2">
            <TxHash hash={entry.transaction_hash} chain={chain!} />
            <div className="text-rex-text-secondary text-xs truncate">
              <AddressDisplay address={entry.from_address} chain={chain!} />
              {' → '}
              {entry.to_address ? (
                <AddressDisplay address={entry.to_address} chain={chain!} />
              ) : 'Create'}
            </div>
            <span className="text-rex-text text-xs font-mono shrink-0">
              {formatInternalValue(entry.value, chain)}
            </span>
            <Badge variant="gray">{entry.call_type}</Badge>
          </div>
        ))}
      </div>

      {data?.next_cursor && (
        <div className="mt-4 text-center">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCursor(data.next_cursor as number)}
            loading={isFetching}
          >
            Load more
          </Button>
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

function formatInternalValue(valueWei: string, chain: string | null): string {
  try {
    const num = BigInt(valueWei)
    if (num === 0n) return `0 ${nativeSymbol(chain)}`
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
    return valueWei
  }
}

const NATIVE_SYMBOLS: Record<string, string> = {
  ethereum: 'ETH', optimism: 'ETH', base: 'ETH', bnb: 'BNB', polygon: 'POL',
}

function nativeSymbol(chain: string | null): string {
  return NATIVE_SYMBOLS[chain || ''] || 'ETH'
}
