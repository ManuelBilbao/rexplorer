import { useState } from 'react'
import type { Operation } from '../../api/types'
import Badge from '../ui/Badge'
import { AddressDisplay } from './AddressDisplay'
import { CopyButton } from './CopyButton'
import { StatusBadge } from './StatusBadge'
import { linkifyAddresses } from '../../lib/linkify'
import { formatAddress } from '../../lib/format'

interface UserOpCardProps {
  /** Every operation the UserOperation produced — more than one if it batched calls. */
  operations: Operation[]
  chain: string
}

/**
 * One ERC-4337 UserOperation: who authored it, who paid for it, whether it
 * succeeded, and the actions it performed. A batched UserOperation lists
 * several actions under one card rather than appearing as several operations.
 */
export function UserOpCard({ operations, chain }: UserOpCardProps) {
  const [showHash, setShowHash] = useState(false)

  const first = operations[0]
  if (!first) return null

  const extra = first.op_extra ?? {}
  const sender = first.from_address
  const hash = extra.user_op_hash

  return (
    <div className="p-4">
      <div className="flex flex-wrap items-center gap-2 mb-2">
        <span className="text-xs font-mono text-rex-text-secondary">#{extra.user_op_index ?? 0}</span>

        <AddressDisplay address={sender} chain={chain} />

        {extra.success !== undefined && <StatusBadge status={extra.success} />}

        {extra.paymaster && <Badge variant="blue">Sponsored</Badge>}

        {extra.factory && <Badge variant="yellow">Account deployed</Badge>}

        {operations.length > 1 && <Badge variant="gray">{operations.length} actions</Badge>}
      </div>

      {/* What the UserOperation actually did */}
      <div className="ml-6 space-y-1">
        {operations.map(operation =>
          operation.decoded_summary ? (
            <p key={operation.operation_index} className="text-sm text-rex-text">
              {linkifyAddresses(operation.decoded_summary, chain)}
            </p>
          ) : (
            <p key={operation.operation_index} className="text-sm text-rex-text-secondary">
              Called {operation.to_address ? formatAddress(operation.to_address) : 'contract'}
            </p>
          ),
        )}
      </div>

      <div className="ml-6 mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-rex-text-secondary">
        {extra.paymaster && (
          <span className="inline-flex items-center gap-1">
            Gas paid by <AddressDisplay address={extra.paymaster} chain={chain} />
          </span>
        )}

        {extra.factory && (
          <span className="inline-flex items-center gap-1">
            Deployed by <AddressDisplay address={extra.factory} chain={chain} />
          </span>
        )}

        {hash && (
          <span className="inline-flex items-center gap-1">
            <button
              type="button"
              onClick={() => setShowHash(v => !v)}
              className="hover:text-rex-text"
            >
              UserOp hash {showHash ? '▾' : '▸'}
            </button>
            {showHash && (
              <>
                <span className="font-mono break-all">{hash}</span>
                <CopyButton value={hash} />
              </>
            )}
          </span>
        )}
      </div>
    </div>
  )
}
