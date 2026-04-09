import { Link, useParams } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useBlock, useTransactions } from '../api/queries'
import { formatBlockNumber, formatGas, formatTimestamp } from '../lib/format'
import Skeleton from '../components/ui/Skeleton'
import DataTable from '../components/ui/DataTable'
import { AddressDisplay } from '../components/explorer/AddressDisplay'
import { TxHash } from '../components/explorer/TxHash'

export function BlockDetailPage() {
  const chain = useChain()
  const { number } = useParams()
  const { data: block, isLoading } = useBlock(chain, number)
  const { data: txData } = useTransactions(chain, { blockNumber: number ? Number(number) : undefined })

  if (isLoading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} width="100%" height="1.5rem" />
        ))}
      </div>
    )
  }

  if (!block) return <div className="text-rex-text-secondary">Block not found</div>

  const txColumns = [
    {
      header: 'Hash',
      accessor: (tx: { hash: string }) => (
        <TxHash hash={tx.hash} chain={chain!} />
      ),
    },
    {
      header: 'From',
      accessor: (tx: { from_address: string }) => {
        if (isLikelyDeposit(tx as { from_address: string; to_address: string | null })) {
          return <span className="text-rex-text-secondary">⬇️ L1 Deposit</span>
        }
        return <AddressDisplay address={tx.from_address} chain={chain!} />
      },
    },
    {
      header: 'To',
      accessor: (tx: { to_address: string | null; from_address: string }) => {
        if (isLikelyDeposit(tx)) return null
        if (!tx.to_address) return <span>Contract Creation</span>
        return <AddressDisplay address={tx.to_address} chain={chain!} />
      },
    },
    {
      header: 'Value',
      accessor: (tx: { value: string }) => (
        <span className="font-mono">{tx.value === '0' ? '0' : tx.value}</span>
      ),
    },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-rex-text">
        Block {formatBlockNumber(block.block_number)}
      </h1>

      <div className="border border-rex-border rounded-lg p-4 mb-6">
        <dl className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <dt className="text-rex-text-secondary">Block Number</dt>
            <dd className="font-mono mt-1">{formatBlockNumber(block.block_number)}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary">Timestamp</dt>
            <dd className="mt-1">{formatTimestamp(block.timestamp)}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary">Hash</dt>
            <dd className="font-mono mt-1 break-all">{block.hash}</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-rex-text-secondary">Parent Hash</dt>
            <dd className="font-mono mt-1 break-all">
              <Link to={`/${chain}/block/${block.block_number - 1}`} className="text-rex-primary hover:underline">
                {block.parent_hash}
              </Link>
            </dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary">Gas Used</dt>
            <dd className="font-mono mt-1">{formatGas(block.gas_used)} / {formatGas(block.gas_limit)}</dd>
          </div>
          <div>
            <dt className="text-rex-text-secondary">Transactions</dt>
            <dd className="mt-1">{block.transaction_count}</dd>
          </div>
          {block.base_fee_per_gas && (
            <div>
              <dt className="text-rex-text-secondary">Base Fee</dt>
              <dd className="font-mono mt-1">{formatGas(block.base_fee_per_gas)} wei</dd>
            </div>
          )}
        </dl>
      </div>

      {txData && txData.data.length > 0 && (
        <div className="border border-rex-border rounded-lg overflow-hidden">
          <h2 className="text-lg font-semibold p-4 text-rex-text">Transactions</h2>
          <DataTable
            columns={txColumns}
            data={txData.data}
            emptyMessage="No transactions in this block"
          />
        </div>
      )}
    </div>
  )
}

function isLikelyDeposit(tx: { from_address: string; to_address: string | null }): boolean {
  const from = tx.from_address?.toLowerCase() || ''
  const to = tx.to_address?.toLowerCase() || ''
  const isBridgeOrZero = (addr: string) =>
    addr === '0x0000000000000000000000000000000000000000' ||
    addr.endsWith('ffff') ||
    /^0x0{30,}/.test(addr)

  return isBridgeOrZero(from) && isBridgeOrZero(to)
}
