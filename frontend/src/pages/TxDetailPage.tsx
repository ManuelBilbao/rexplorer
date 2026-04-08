import { useState } from 'react'
import { useParams, Link } from 'react-router'
import { useChain } from '../hooks/useChain'
import { useTxDetail } from '../api/queries'
import { formatAmount, formatGas, timeAgo } from '../lib/format'
import { EffectsSection } from '../components/explorer/EffectsSection'
import { linkifyAddresses } from '../lib/linkify'

function actionIcon(summary: string | null): string {
  if (!summary) return '📝'
  const s = summary.toLowerCase()
  if (s.includes('deposited') && s.includes('from l1')) return '⬇️'
  if (s.includes('swap')) return '🔀'
  if (s.includes('transfer')) return '→'
  if (s.includes('approv')) return '✓'
  if (s.includes('wrap')) return '🔄'
  if (s.includes('supply') || s.includes('deposit')) return '↓'
  if (s.includes('withdraw') || s.includes('unwrap')) return '↑'
  if (s.includes('borrow')) return '🏦'
  if (s.includes('repay')) return '↩'
  if (s.includes('safe')) return '🔐'
  return '📝'
}

export function TxDetailPage() {
  const chain = useChain()
  const { hash } = useParams()
  const { data, isLoading } = useTxDetail(chain, hash)
  const [advanced, setAdvanced] = useState(false)

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-32 bg-rex-bg-secondary border border-rex-border rounded-xl animate-pulse" />
        <div className="h-24 bg-rex-bg-secondary border border-rex-border rounded-xl animate-pulse" />
        <div className="h-48 bg-rex-bg-secondary border border-rex-border rounded-xl animate-pulse" />
      </div>
    )
  }

  if (!data) return <div className="text-rex-text-secondary py-12 text-center">Transaction not found</div>

  const tx = data.transaction
  const isFrameTx = tx.transaction_type === 6 && data.frames && data.frames.length > 0
  const mainSummary = data.operations.find(op => op.decoded_summary)?.decoded_summary
  const opType = data.operations[0]?.operation_type

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-rex-text">Transaction</h1>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setAdvanced(false)}
            className={`px-3 py-1 text-xs rounded-lg transition-colors ${!advanced ? 'bg-rex-primary text-white' : 'bg-rex-bg-tertiary text-rex-text-secondary hover:text-rex-text'}`}
          >
            Simple
          </button>
          <button
            onClick={() => setAdvanced(true)}
            className={`px-3 py-1 text-xs rounded-lg transition-colors ${advanced ? 'bg-rex-primary text-white' : 'bg-rex-bg-tertiary text-rex-text-secondary hover:text-rex-text'}`}
          >
            Advanced
          </button>
        </div>
      </div>

      {/* Story Hero */}
      <div className={`bg-rex-bg-secondary border border-rex-border rounded-xl p-6 border-l-4 ${chainBorderColor(chain)}`}>
        {mainSummary ? (
          <div className="flex items-start gap-4">
            <span className="text-2xl mt-0.5">{actionIcon(mainSummary)}</span>
            <div className="flex-1">
              <p className="text-lg font-medium text-rex-text leading-relaxed">
                {linkifyAddresses(mainSummary, chain)}
              </p>
              <div className="flex items-center gap-3 mt-3 text-xs text-rex-text-secondary">
                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded font-medium ${
                  tx.status === true ? 'bg-rex-success/10 text-rex-success' :
                  tx.status === false ? 'bg-rex-danger/10 text-rex-danger' :
                  'bg-rex-bg-tertiary text-rex-text-secondary'
                }`}>
                  {tx.status === true ? '✓ Success' : tx.status === false ? '✗ Failed' : '⏳ Pending'}
                </span>
                <ChainBadge chain={chain} />
                {tx.block_number && <Link to={`/${chain}/block/${tx.block_number}`} className="hover:text-rex-primary">Block {tx.block_number.toLocaleString()}</Link>}
                {tx.block_timestamp && <span>{timeAgo(tx.block_timestamp)}</span>}
              </div>
            </div>
          </div>
        ) : (
          <div>
            <div className="flex items-center gap-3 mb-2">
              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium ${
                tx.status === true ? 'bg-rex-success/10 text-rex-success' :
                tx.status === false ? 'bg-rex-danger/10 text-rex-danger' :
                'bg-rex-bg-tertiary text-rex-text-secondary'
              }`}>
                {tx.status === true ? '✓ Success' : tx.status === false ? '✗ Failed' : '⏳ Pending'}
              </span>
              <ChainBadge chain={chain} />
              {opType && opType !== 'call' && (
                <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary text-rex-text-secondary">{opType}</span>
              )}
            </div>
            <p className="text-sm text-rex-text-secondary">
              Block {tx.block_number?.toLocaleString()}
              {tx.block_timestamp && <> · {timeAgo(tx.block_timestamp)}</>}
            </p>
          </div>
        )}
      </div>

      {/* What Happened */}
      {(data.token_transfers.length > 0 || data.logs.some(l => l.decoded)) && (
        <EffectsSection tokenTransfers={data.token_transfers} logs={data.logs} depositSummary={mainSummary?.toLowerCase().includes('deposited') && mainSummary?.toLowerCase().includes('from l1') ? mainSummary : undefined} />
      )}

      {/* Details */}
      <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
        <div className="px-5 py-3 border-b border-rex-border">
          <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">Details</h2>
        </div>
        <div className="divide-y divide-rex-border">
          <DetailRow label="Hash" value={hash || ''} mono copyable />
          <DetailRow label="Block" value={tx.block_number?.toLocaleString() ?? '-'} link={tx.block_number ? `/${chain}/block/${tx.block_number}` : undefined} />
          <DetailRow label="From" value={tx.from_address} mono copyable link={`/${chain}/address/${tx.from_address}`} />
          {isFrameTx ? (
            <DetailRow label="Sender" value={tx.from_address} mono copyable link={`/${chain}/address/${tx.from_address}`} />
          ) : (
            <DetailRow label="To" value={tx.to_address ?? 'Contract Creation'} mono copyable link={tx.to_address ? `/${chain}/address/${tx.to_address}` : undefined} />
          )}
          {isFrameTx && tx.payer && tx.payer !== tx.from_address && (
            <DetailRow label="Payer" value={tx.payer} mono copyable link={`/${chain}/address/${tx.payer}`} />
          )}
          {!isFrameTx && <DetailRow label="Value" value={formatAmount(tx.value, 18, nativeSymbol(chain))} />}
          <DetailRow label="Gas Used" value={tx.gas_used ? formatGas(tx.gas_used) : '-'} />
          {tx.gas_price && <DetailRow label="Gas Price" value={`${(tx.gas_price / 1e9).toFixed(2)} gwei`} />}
          {opType && <DetailRow label="Operation Type" value={opType} />}
          <DetailRow label="Nonce" value={String(tx.nonce)} />
          {tx.transaction_type != null && <DetailRow label="Tx Type" value={isFrameTx ? 'Frame (0x06)' : String(tx.transaction_type)} />}
        </div>
      </div>

      {/* Frames (EIP-8141) */}
      {isFrameTx && data.frames.length > 0 && (
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
          <div className="px-5 py-3 border-b border-rex-border">
            <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">
              Frames ({data.frames.length})
            </h2>
          </div>
          <div className="divide-y divide-rex-border">
            {data.frames.map(frame => {
              const frameOps = data.operations.filter(op => op.frame_index === frame.frame_index)
              const frameLogs = data.logs.filter(l => l.frame_index === frame.frame_index)
              const frameTransfers = data.token_transfers.filter(t => t.frame_index === frame.frame_index)

              return (
                <div key={frame.frame_index} className="p-4">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="text-xs font-mono text-rex-text-secondary">#{frame.frame_index}</span>
                    <span className={`px-2 py-0.5 text-xs rounded font-medium ${
                      (frame.mode & 0xFF) === 1 ? 'bg-blue-500/10 text-blue-500' :
                      (frame.mode & 0xFF) === 2 ? 'bg-rex-primary/10 text-rex-primary' :
                      'bg-rex-bg-tertiary text-rex-text-secondary'
                    }`}>
                      {modeLabel(frame.mode)}
                    </span>
                    {frame.target && (
                      <Link to={`/${chain}/address/${frame.target}`} className="text-xs font-mono text-rex-primary hover:underline">
                        {frame.target.slice(0, 10)}...{frame.target.slice(-4)}
                      </Link>
                    )}
                    <span className={`ml-auto px-2 py-0.5 text-xs rounded ${
                      frame.status === true ? 'bg-rex-success/10 text-rex-success' :
                      frame.status === false ? 'bg-rex-danger/10 text-rex-danger' :
                      'bg-rex-bg-tertiary text-rex-text-secondary'
                    }`}>
                      {frame.status === true ? '✓' : frame.status === false ? '✗' : '...'}
                    </span>
                    {frame.gas_used != null && (
                      <span className="text-xs text-rex-text-secondary">{formatGas(frame.gas_used)} gas</span>
                    )}
                  </div>
                  {/* Decoded operations for this frame */}
                  {frameOps.map(op => op.decoded_summary && (
                    <p key={op.operation_index} className="text-sm text-rex-text ml-6 mb-1">
                      {linkifyAddresses(op.decoded_summary, chain)}
                    </p>
                  ))}
                  {(frame.mode & 0xFF) === 1 && frameOps.length === 0 && (
                    <p className="text-sm text-rex-text-secondary ml-6">
                      {verifyDescription(frame.target, tx.from_address, tx.payer)}
                    </p>
                  )}
                  {/* Token transfers for this frame */}
                  {frameTransfers.map((t, i) => (
                    <div key={i} className="text-xs font-mono text-rex-text-secondary ml-6">
                      Transfer: {t.amount} {t.token_type} {t.from_address.slice(0, 8)}... → {t.to_address.slice(0, 8)}...
                    </div>
                  ))}
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Advanced: Operations detail */}
      {advanced && data.operations.length > 0 && (
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
          <div className="px-5 py-3 border-b border-rex-border">
            <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">
              Operations ({data.operations.length})
            </h2>
          </div>
          <div className="divide-y divide-rex-border">
            {data.operations.map(op => (
              <div key={op.operation_index} className="p-4 text-sm">
                <div className="flex items-center gap-2 mb-2">
                  <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary font-mono">{op.operation_type}</span>
                  <span className="text-rex-text-secondary text-xs">#{op.operation_index}</span>
                </div>
                {op.decoded_summary && <p className="text-rex-text mb-2">{linkifyAddresses(op.decoded_summary, chain)}</p>}
                <div className="text-xs font-mono text-rex-text-secondary space-y-1">
                  <div>From: {op.from_address}</div>
                  <div>To: {op.to_address}</div>
                  <div>Value: {op.value}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Advanced: Event Logs */}
      {advanced && data.logs.length > 0 && (
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
          <div className="px-5 py-3 border-b border-rex-border">
            <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">
              Event Logs ({data.logs.length})
            </h2>
          </div>
          <div className="divide-y divide-rex-border">
            {data.logs.map(log => (
              <div key={log.log_index} className="p-4">
                <div className="flex items-center gap-2 mb-2 text-xs">
                  <span className="px-2 py-0.5 rounded bg-rex-bg-tertiary font-mono">#{log.log_index}</span>
                  <Link to={`/${chain}/address/${log.contract_address}`} className="font-mono text-rex-primary hover:underline">
                    {log.contract_address.slice(0, 10)}...{log.contract_address.slice(-4)}
                  </Link>
                </div>
                {log.decoded && (
                  <p className="text-sm text-rex-text mb-2">
                    {linkifyAddresses((log.decoded as { summary?: string }).summary || '', chain)}
                  </p>
                )}
                <div className="text-xs font-mono text-rex-text-secondary space-y-0.5">
                  {log.topic0 && <div className="truncate">topic0: {log.topic0}</div>}
                  {log.topic1 && <div className="truncate">topic1: {log.topic1}</div>}
                  {log.topic2 && <div className="truncate">topic2: {log.topic2}</div>}
                  {log.topic3 && <div className="truncate">topic3: {log.topic3}</div>}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Cross-chain links */}
      {data.cross_chain_links.length > 0 && (
        <div className="bg-rex-bg-secondary border border-rex-border rounded-xl overflow-hidden">
          <div className="px-5 py-3 border-b border-rex-border">
            <h2 className="text-sm font-semibold text-rex-text-secondary uppercase tracking-wide">Cross-Chain Journey</h2>
          </div>
          <div className="p-4">
            {data.cross_chain_links.map((link, i) => (
              <div key={i} className="flex items-center gap-3 text-sm">
                <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary">{link.link_type}</span>
                <span className="px-2 py-0.5 text-xs rounded bg-rex-bg-tertiary">{link.status}</span>
                <span className="text-xs font-mono text-rex-text-secondary">
                  Chain {link.source_chain_id} → Chain {link.destination_chain_id}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function DetailRow({ label, value, mono, copyable, link }: { label: string; value: string; mono?: boolean; copyable?: boolean; link?: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = () => {
    navigator.clipboard.writeText(value)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  const valueClass = `flex-1 break-all ${mono ? 'font-mono text-xs' : ''}`

  return (
    <div className="flex items-center px-5 py-3 text-sm">
      <span className="w-32 shrink-0 text-rex-text-secondary text-xs uppercase tracking-wide">{label}</span>
      {link ? (
        <Link to={link} className={`${valueClass} text-rex-primary hover:underline`}>{value}</Link>
      ) : (
        <span className={`${valueClass} text-rex-text`}>{value}</span>
      )}
      {copyable && (
        <button onClick={handleCopy} className="ml-2 text-rex-text-secondary hover:text-rex-text shrink-0 cursor-pointer">
          {copied ? (
            <span className="text-xs text-rex-success">✓</span>
          ) : (
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <rect x="9" y="9" width="13" height="13" rx="2" ry="2" strokeWidth={1.5} />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
            </svg>
          )}
        </button>
      )}
    </div>
  )
}

const CHAIN_COLORS: Record<string, { border: string; dot: string; name: string }> = {
  ethereum: { border: 'border-l-blue-500', dot: 'bg-blue-500', name: 'Ethereum' },
  optimism: { border: 'border-l-red-500', dot: 'bg-red-500', name: 'Optimism' },
  base: { border: 'border-l-blue-600', dot: 'bg-blue-600', name: 'Base' },
  bnb: { border: 'border-l-yellow-500', dot: 'bg-yellow-500', name: 'BNB Chain' },
  polygon: { border: 'border-l-purple-500', dot: 'bg-purple-500', name: 'Polygon' },
}

const NATIVE_SYMBOLS: Record<string, string> = {
  ethereum: 'ETH', optimism: 'ETH', base: 'ETH', bnb: 'BNB', polygon: 'POL',
}

function nativeSymbol(chain: string | null): string {
  return NATIVE_SYMBOLS[chain || ''] || 'ETH'
}

function chainBorderColor(chain: string | null): string {
  return CHAIN_COLORS[chain || '']?.border || 'border-l-rex-primary'
}

function modeLabel(mode: number): string {
  switch (mode & 0xFF) {
    case 0: return 'DEFAULT'
    case 1: return 'VERIFY'
    case 2: return 'SENDER'
    default: return `MODE(${mode})`
  }
}

function verifyDescription(target: string | null, sender: string, payer: string | null): string {
  const t = target?.toLowerCase()
  const s = sender?.toLowerCase()
  const p = payer?.toLowerCase()

  if (t && t === s && t === p) return 'Approved execution & payment'
  if (t && t === s) return 'Approved execution'
  if (t && t === p) return 'Approved payment'
  return 'Signature verification'
}

function ChainBadge({ chain }: { chain: string | null }) {
  const info = CHAIN_COLORS[chain || '']
  if (!info) return null

  return (
    <span className="inline-flex items-center gap-1.5">
      <span className={`w-2 h-2 rounded-full ${info.dot}`} />
      <span>{info.name}</span>
    </span>
  )
}
