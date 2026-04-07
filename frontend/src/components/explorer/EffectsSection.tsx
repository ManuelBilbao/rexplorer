import { Link } from 'react-router'
import { useChain } from '../../hooks/useChain'
import { linkifyAddresses } from '../../lib/linkify'
import type { TokenTransfer, Log } from '../../api/types'

interface EffectsSectionProps {
  tokenTransfers: TokenTransfer[]
  logs: Log[]
  depositSummary?: string
}

interface DecodedLog {
  event_name: string
  params: Record<string, string | null>
  summary: string
}

export function EffectsSection({ tokenTransfers, logs, depositSummary }: EffectsSectionProps) {
  const chain = useChain()

  const decodedLogs = logs
    .filter((log) => log.decoded != null)
    .map((log) => log.decoded as unknown as DecodedLog)

  const hasDecodedTransfers = decodedLogs.some((dl) => dl.event_name === 'Transfer')
  const hasDecodedDeposit = decodedLogs.some((dl) => dl.event_name === 'DepositProcessed')
  const showRawTransfers = !hasDecodedTransfers && tokenTransfers.length > 0
  const rawTransfers = showRawTransfers ? tokenTransfers.filter((t) => !(hasDecodedDeposit && isDepositTransfer(t))) : []
  const hasEffects = decodedLogs.length > 0 || rawTransfers.length > 0

  if (!hasEffects) {
    return (
      <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
        <div className="px-5 py-3 border-b border-rex-border">
          <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">What Happened</h2>
        </div>
        <p className="px-5 py-3 text-sm text-rex-text-secondary">No decoded effects</p>
      </div>
    )
  }

  return (
    <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
      <div className="px-5 py-3 border-b border-rex-border">
        <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">What Happened</h2>
      </div>
      <div className="divide-y divide-rex-border">
        {decodedLogs.map((dl, i) => (
          <div key={`event-${i}`} className="flex items-center gap-3 text-sm px-5 py-3">
            <span className="text-base shrink-0">{eventIcon(dl.event_name)}</span>
            <span className="text-rex-text">{linkifyAddresses(dl.summary, chain)}</span>
          </div>
        ))}

        {rawTransfers.map((t, i) => {
          const deposit = isDepositTransfer(t)

          return (
            <div key={`xfer-${i}`} className="flex items-center gap-3 text-sm px-5 py-3">
              <span className="text-base shrink-0">{deposit ? '⬇️' : '→'}</span>
              <span className="text-rex-text">
                {deposit && depositSummary ? (
                  <>{linkifyAddresses(depositSummary, chain)}</>
                ) : deposit ? (
                  <>L1 Deposit: {formatTransferAmount(t)} {tokenLabel(t, chain)}</>
                ) : (
                  <>
                    {formatTransferAmount(t)} {tokenLabel(t, chain)}{' '}
                    <Link to={`/${chain}/address/${t.from_address}`} className="text-rex-primary hover:underline font-mono">
                      {t.from_address.slice(0, 6)}...{t.from_address.slice(-4)}
                    </Link>
                    {' → '}
                    <Link to={`/${chain}/address/${t.to_address}`} className="text-rex-primary hover:underline font-mono">
                      {t.to_address.slice(0, 6)}...{t.to_address.slice(-4)}
                    </Link>
                  </>
                )}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}

const NATIVE_SYMBOLS: Record<string, string> = {
  ethereum: 'ETH',
  optimism: 'ETH',
  base: 'ETH',
  bnb: 'BNB',
  polygon: 'POL',
}

function formatTransferAmount(t: TokenTransfer): string {
  if (t.token_type === 'native') {
    return formatWithDecimals(t.amount, 18)
  }
  // For ERC-20 in raw fallback, we don't have decimals info — show raw
  return t.amount
}

function formatWithDecimals(raw: string, decimals: number): string {
  try {
    const num = BigInt(raw)
    const divisor = BigInt(10 ** decimals)
    const whole = num / divisor
    const remainder = num % divisor

    if (remainder === 0n) {
      return whole.toLocaleString()
    }

    const fracStr = remainder.toString().padStart(decimals, '0')
    const trimmed = fracStr.replace(/0+$/, '')
    const display = trimmed.slice(0, 6)
    return `${whole.toLocaleString()}.${display}`
  } catch {
    return raw
  }
}

function isDepositTransfer(t: TokenTransfer): boolean {
  const isBridgeOrZero = (addr: string) =>
    addr === '0x0000000000000000000000000000000000000000' ||
    addr.toLowerCase().endsWith('ffff') ||
    /^0x0{30,}/.test(addr)

  return t.token_type === 'native' && isBridgeOrZero(t.from_address) && isBridgeOrZero(t.to_address)
}

function tokenLabel(t: TokenTransfer, chain: string | null): string {
  if (t.token_type === 'native') {
    return NATIVE_SYMBOLS[chain || ''] || 'ETH'
  }
  return t.token_type.toUpperCase()
}

function eventIcon(eventName: string): string {
  switch (eventName) {
    case 'Transfer': return '→'
    case 'Approval': return '✓'
    case 'Swap': return '↔'
    case 'DepositProcessed': return '⬇️'
    case 'Supply': case 'Deposit': return '↓'
    case 'Withdraw': case 'Withdrawal': return '↑'
    case 'Borrow': return '↓'
    case 'Repay': return '↑'
    default: return '⚡'
  }
}
