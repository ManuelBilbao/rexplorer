import { useState } from 'react'
import { useChain } from '../hooks/useChain'
import { useBlocks } from '../api/queries'
import { formatGas } from '../lib/format'
import DataTable from '../components/ui/DataTable'
import { BlockNumber } from '../components/explorer/BlockNumber'
import { TimeAgo } from '../components/explorer/TimeAgo'

export function BlockListPage() {
  const chain = useChain()
  const [cursor, setCursor] = useState<number | undefined>()
  const { data, isLoading } = useBlocks(chain, cursor)

  const columns = [
    {
      header: 'Block',
      accessor: (block: { block_number: number }) => (
        <BlockNumber number={block.block_number} chain={chain!} />
      ),
    },
    {
      header: 'Age',
      accessor: (block: { timestamp: string }) => (
        <TimeAgo timestamp={block.timestamp} />
      ),
    },
    {
      header: 'Txs',
      accessor: (block: { transaction_count: number }) => (
        <span className="text-right block">{block.transaction_count}</span>
      ),
    },
    {
      header: 'Gas Used',
      accessor: (block: { gas_used: number }) => (
        <span className="text-right block font-mono text-rex-text-secondary">{formatGas(block.gas_used)}</span>
      ),
    },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-rex-text">Blocks</h1>

      <div className="border border-rex-border rounded-lg overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.data || []}
          loading={isLoading}
          emptyMessage="No blocks found"
          hasMore={data?.next_cursor != null}
          onLoadMore={() => data?.next_cursor != null && setCursor(Number(data.next_cursor))}
        />
      </div>
    </div>
  )
}
