import type { TokenTransfer, Log } from '../../api/types'

interface EffectsSectionProps {
  tokenTransfers: TokenTransfer[]
  logs: Log[]
}

interface DecodedLog {
  event_name: string
  params: Record<string, string | null>
  summary: string
}

export function EffectsSection({ tokenTransfers, logs }: EffectsSectionProps) {
  const decodedLogs = logs
    .filter((log) => log.decoded != null)
    .map((log) => log.decoded as unknown as DecodedLog)

  // Strategy: show decoded log summaries (which include Transfers with proper formatting).
  // Only fall back to raw token_transfers for transfers that weren't decoded as logs.
  const decodedLogCount = decodedLogs.length
  const hasDecodedTransfers = decodedLogs.some((dl) => dl.event_name === 'Transfer')

  // If we have decoded logs, show those (they have human-readable summaries).
  // If no decoded logs exist, fall back to raw token_transfers.
  const showRawTransfers = !hasDecodedTransfers && tokenTransfers.length > 0
  const hasEffects = decodedLogCount > 0 || showRawTransfers

  if (!hasEffects) {
    return (
      <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
        <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Effects</h2>
        <p className="text-sm text-rex-text-secondary dark:text-rex-text-secondary-dark">No decoded effects</p>
      </div>
    )
  }

  return (
    <div className="border border-rex-border dark:border-rex-border-dark rounded-lg p-4">
      <h2 className="text-lg font-semibold mb-3 text-rex-text dark:text-rex-text-dark">Effects</h2>
      <div className="space-y-2">
        {/* Decoded events with human-readable summaries */}
        {decodedLogs.map((dl, i) => (
          <div key={`event-${i}`} className="flex items-center gap-2 text-sm p-2 rounded bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark">
            <span className="text-lg">{eventIcon(dl.event_name)}</span>
            <span className="text-rex-text dark:text-rex-text-dark">{dl.summary}</span>
          </div>
        ))}

        {/* Fallback: raw token transfers (only if no decoded Transfer logs exist) */}
        {showRawTransfers && tokenTransfers.map((t, i) => (
          <div key={`xfer-${i}`} className="flex items-center gap-2 text-sm p-2 rounded bg-rex-bg-secondary dark:bg-rex-bg-secondary-dark">
            <span className="text-lg">→</span>
            <span className="text-rex-text dark:text-rex-text-dark">
              {t.amount} ({t.token_type}) {truncate(t.from_address)} → {truncate(t.to_address)}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

function eventIcon(eventName: string): string {
  switch (eventName) {
    case 'Transfer': return '→'
    case 'Approval': return '✓'
    case 'Swap': return '↔'
    case 'Supply': case 'Deposit': return '↓'
    case 'Withdraw': case 'Withdrawal': return '↑'
    case 'Borrow': return '↓'
    case 'Repay': return '↑'
    default: return '⚡'
  }
}

function truncate(addr: string): string {
  if (addr.length > 12) {
    return addr.slice(0, 6) + '...' + addr.slice(-4)
  }
  return addr
}
