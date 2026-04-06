import { useState } from 'react'

const palettes = {
  ocean: {
    name: 'Deep Ocean',
    description: 'Calm, professional — like Linear meets a trading terminal',
    bg: '#0a0f1a',
    card: '#111827',
    surface: '#1e293b',
    primary: '#6366f1',
    primaryHover: '#818cf8',
    success: '#34d399',
    danger: '#f87171',
    warning: '#fbbf24',
    text: '#e2e8f0',
    textSecondary: '#94a3b8',
    border: '#1e293b',
    muted: '#64748b',
  },
  fossil: {
    name: 'Fossil (original)',
    description: 'Original — too dark bg, strident yellow',
    bg: '#0f0f14',
    card: '#1a1a24',
    surface: '#252530',
    primary: '#f59e0b',
    primaryHover: '#fbbf24',
    success: '#22c55e',
    danger: '#ef4444',
    warning: '#f59e0b',
    text: '#f1f5f9',
    textSecondary: '#a1a1aa',
    border: '#27272a',
    muted: '#71717a',
  },
  fossilV2: {
    name: 'Fossil v2',
    description: 'Softer amber, lighter bg, muted labels — warm but not loud',
    bg: '#141418',
    card: '#1c1c22',
    surface: '#2a2a32',
    primary: '#d4985a',
    primaryHover: '#e0a96a',
    success: '#5cb87a',
    danger: '#d96b6b',
    warning: '#d4985a',
    text: '#e8e4df',
    textSecondary: '#9a9590',
    border: '#2e2e35',
    muted: '#6e6a65',
  },
  fossilV3: {
    name: 'Fossil v3',
    description: 'Sandy amber, warmer grays, earthy feel — like weathered stone',
    bg: '#161614',
    card: '#1e1e1b',
    surface: '#2b2b27',
    primary: '#c8956c',
    primaryHover: '#d9a87e',
    success: '#6fad7b',
    danger: '#c76a6a',
    warning: '#c8956c',
    text: '#e5e0d9',
    textSecondary: '#958e84',
    border: '#33322e',
    muted: '#6d6860',
  },
  fossilV4: {
    name: 'Fossil v4 (dark)',
    description: 'Copper accent on cool dark — warmth without muddiness',
    bg: '#111116',
    card: '#19191f',
    surface: '#24242b',
    primary: '#cd8b5e',
    primaryHover: '#dba070',
    success: '#5dba7d',
    danger: '#d4706f',
    warning: '#cd8b5e',
    text: '#eae8e4',
    textSecondary: '#908c87',
    border: '#2a2a31',
    muted: '#686560',
  },
  fossilV4Light: {
    name: 'Fossil v4 (light)',
    description: 'Same copper accent, warm light background — daytime mode',
    bg: '#faf8f5',
    card: '#ffffff',
    surface: '#f3f0ec',
    primary: '#b07a4a',
    primaryHover: '#9a6a3d',
    success: '#3d8f55',
    danger: '#c4534f',
    warning: '#b07a4a',
    text: '#1c1917',
    textSecondary: '#6b6560',
    border: '#e5e0da',
    muted: '#9a9590',
  },
  terminal: {
    name: 'Neon Terminal',
    description: 'Developer-first, high contrast — like Warp or a hacker tool',
    bg: '#09090b',
    card: '#18181b',
    surface: '#27272a',
    primary: '#22d3ee',
    primaryHover: '#67e8f9',
    success: '#4ade80',
    danger: '#fb7185',
    warning: '#facc15',
    text: '#fafafa',
    textSecondary: '#a1a1aa',
    border: '#27272a',
    muted: '#71717a',
  },
}

type PaletteKey = keyof typeof palettes

export function DesignPreview() {
  const [active, setActive] = useState<PaletteKey>('ocean')
  const p = palettes[active]

  return (
    <div style={{ background: p.bg, color: p.text, minHeight: '100vh', padding: '24px', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif' }}>
      {/* Palette selector */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '32px' }}>
        {(Object.keys(palettes) as PaletteKey[]).map(key => (
          <button
            key={key}
            onClick={() => setActive(key)}
            style={{
              padding: '10px 20px',
              borderRadius: '8px',
              border: active === key ? `2px solid ${palettes[key].primary}` : `1px solid ${palettes[key].border}`,
              background: active === key ? palettes[key].surface : palettes[key].card,
              color: active === key ? palettes[key].primary : palettes[key].text,
              cursor: 'pointer',
              fontWeight: active === key ? 700 : 400,
              fontSize: '14px',
            }}
          >
            {palettes[key].name}
          </button>
        ))}
      </div>

      <p style={{ color: p.textSecondary, marginBottom: '32px', fontSize: '14px' }}>{p.description}</p>

      {/* Header mock */}
      <div style={{ borderBottom: `1px solid ${p.border}`, padding: '16px 0', marginBottom: '32px', display: 'flex', alignItems: 'center', gap: '16px' }}>
        <span style={{ fontSize: '22px', fontWeight: 700, color: p.primary }}>
          {active === 'fossil' ? '🦕 ' : ''}rexplorer
        </span>
        <div style={{ flex: 1, maxWidth: '500px' }}>
          <input
            placeholder="Search by address, tx hash, or block..."
            style={{
              width: '100%',
              padding: '10px 16px',
              borderRadius: '10px',
              border: `1px solid ${p.border}`,
              background: p.surface,
              color: p.text,
              fontSize: '14px',
              outline: 'none',
            }}
          />
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <span style={{ fontSize: '14px', color: p.textSecondary }}>Ethereum</span>
          <span style={{ fontSize: '18px', cursor: 'pointer' }}>🌙</span>
        </div>
      </div>

      {/* Network stats */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '16px',
        marginBottom: '32px',
      }}>
        {[
          { label: 'Block Height', value: '20,847,293', sub: '12s ago' },
          { label: 'Gas Price', value: '8.2 gwei', sub: 'Base: 7.1' },
          { label: 'Transactions', value: '1.2M / day', sub: '~14 TPS' },
          { label: 'Active Addresses', value: '547K', sub: 'Last 24h' },
        ].map(stat => (
          <div key={stat.label} style={{
            background: p.card,
            border: `1px solid ${p.border}`,
            borderRadius: '12px',
            padding: '20px',
          }}>
            <div style={{ fontSize: '12px', color: p.muted, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{stat.label}</div>
            <div style={{ fontSize: '24px', fontWeight: 700 }}>{stat.value}</div>
            <div style={{ fontSize: '12px', color: p.textSecondary, marginTop: '4px' }}>{stat.sub}</div>
          </div>
        ))}
      </div>

      {/* Two column: Blocks + something useful */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '32px' }}>
        {/* Latest Blocks */}
        <div style={{ background: p.card, border: `1px solid ${p.border}`, borderRadius: '12px', padding: '20px' }}>
          <h2 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>Latest Blocks</h2>
          {[
            { num: '20,847,293', txs: 152, time: '2s ago', gasPercent: 87 },
            { num: '20,847,292', txs: 98, time: '14s ago', gasPercent: 62 },
            { num: '20,847,291', txs: 201, time: '26s ago', gasPercent: 94 },
            { num: '20,847,290', txs: 134, time: '38s ago', gasPercent: 78 },
            { num: '20,847,289', txs: 176, time: '50s ago', gasPercent: 83 },
          ].map(block => (
            <div key={block.num} style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 0',
              borderBottom: `1px solid ${p.border}`,
              fontSize: '14px',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: p.success }} />
                <span style={{ color: p.primary, fontFamily: 'monospace', fontWeight: 500, cursor: 'pointer' }}>{block.num}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                <span style={{ color: p.textSecondary }}>{block.txs} txs</span>
                {/* Gas bar */}
                <div style={{ width: '60px', height: '4px', background: p.surface, borderRadius: '2px' }}>
                  <div style={{ width: `${block.gasPercent}%`, height: '100%', background: block.gasPercent > 90 ? p.danger : block.gasPercent > 70 ? p.warning : p.success, borderRadius: '2px' }} />
                </div>
                <span style={{ color: p.muted, fontSize: '12px', width: '50px', textAlign: 'right' }}>{block.time}</span>
              </div>
            </div>
          ))}
          <div style={{ textAlign: 'center', paddingTop: '12px' }}>
            <span style={{ color: p.primary, fontSize: '13px', cursor: 'pointer' }}>View all blocks →</span>
          </div>
        </div>

        {/* Chain overview / quick stats */}
        <div style={{ background: p.card, border: `1px solid ${p.border}`, borderRadius: '12px', padding: '20px' }}>
          <h2 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>Network Overview</h2>

          {/* Top protocols */}
          <div style={{ marginBottom: '20px' }}>
            <div style={{ fontSize: '12px', color: p.muted, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>Top Protocols (24h)</div>
            {[
              { name: 'Uniswap V3', txs: '45.2K', color: p.primary },
              { name: 'Aave V3', txs: '12.8K', color: p.primary },
              { name: 'Safe', txs: '8.4K', color: p.primary },
              { name: 'USDC', txs: '67.1K', color: p.primary },
            ].map(proto => (
              <div key={proto.name} style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '8px 0',
                fontSize: '14px',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: proto.color }} />
                  <span>{proto.name}</span>
                </div>
                <span style={{ color: p.textSecondary, fontFamily: 'monospace', fontSize: '13px' }}>{proto.txs}</span>
              </div>
            ))}
          </div>

          {/* Gas price chart placeholder */}
          <div style={{ marginBottom: '20px' }}>
            <div style={{ fontSize: '12px', color: p.muted, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>Gas Price (1h)</div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: '3px', height: '48px' }}>
              {[30, 45, 35, 60, 80, 55, 40, 35, 50, 65, 45, 38, 42, 58, 70, 48, 35, 40, 55, 45, 38, 52, 60, 42].map((h, i) => (
                <div key={i} style={{ flex: 1, height: `${h}%`, background: p.primary, borderRadius: '2px', opacity: i === 23 ? 1 : 0.5 }} />
              ))}
            </div>
          </div>

          {/* Quick links */}
          <div>
            <div style={{ fontSize: '12px', color: p.muted, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>Quick Links</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
              {['Top Tokens', 'Verified Contracts', 'API Docs', 'Gas Tracker'].map(link => (
                <span key={link} style={{
                  padding: '6px 12px',
                  borderRadius: '6px',
                  background: p.surface,
                  fontSize: '12px',
                  color: p.primary,
                  cursor: 'pointer',
                }}>
                  {link}
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Transaction detail mock */}
      <div style={{ background: p.card, border: `1px solid ${p.border}`, borderRadius: '12px', padding: '24px', marginBottom: '32px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 style={{ fontSize: '18px', fontWeight: 600 }}>Transaction Detail</h2>
          <div style={{ display: 'flex', gap: '8px' }}>
            <span style={{ padding: '4px 12px', borderRadius: '6px', background: p.surface, fontSize: '12px', color: p.textSecondary, cursor: 'pointer' }}>Simple</span>
            <span style={{ padding: '4px 12px', borderRadius: '6px', background: p.primary + '20', fontSize: '12px', color: p.primary, cursor: 'pointer', fontWeight: 600 }}>Advanced</span>
          </div>
        </div>

        {/* Story banner */}
        <div style={{
          background: p.surface,
          borderRadius: '10px',
          padding: '20px',
          marginBottom: '20px',
          borderLeft: `3px solid ${p.primary}`,
        }}>
          <div style={{ fontSize: '16px', fontWeight: 500, lineHeight: '1.5' }}>
            Safe <span style={{ color: p.primary, fontFamily: 'monospace' }}>0x7a25...488d</span> swapped <span style={{ fontWeight: 700 }}>10 ETH</span> for <span style={{ fontWeight: 700 }}>25,247 USDC</span> on <span style={{ color: p.primary }}>Uniswap V3</span>
          </div>
        </div>

        {/* Status row */}
        <div style={{ display: 'flex', gap: '24px', marginBottom: '20px', fontSize: '14px' }}>
          <div>
            <span style={{ color: p.muted, marginRight: '8px' }}>Status</span>
            <span style={{ padding: '3px 10px', borderRadius: '4px', background: p.success + '20', color: p.success, fontSize: '12px', fontWeight: 600 }}>Success</span>
          </div>
          <div>
            <span style={{ color: p.muted, marginRight: '8px' }}>Block</span>
            <span style={{ color: p.primary, fontFamily: 'monospace' }}>20,847,291</span>
          </div>
          <div>
            <span style={{ color: p.muted, marginRight: '8px' }}>Type</span>
            <span style={{ padding: '3px 10px', borderRadius: '4px', background: p.surface, fontSize: '12px' }}>multisig_execution</span>
          </div>
          <div>
            <span style={{ color: p.muted, marginRight: '8px' }}>Gas</span>
            <span style={{ fontFamily: 'monospace' }}>0.0041 ETH</span>
          </div>
        </div>

        {/* Effects */}
        <div style={{ marginBottom: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '12px', color: p.textSecondary }}>Effects</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 14px', background: p.surface, borderRadius: '8px', fontSize: '13px' }}>
              <span style={{ fontSize: '16px' }}>↓</span>
              <span style={{ fontWeight: 600 }}>10 WETH</span>
              <span style={{ color: p.muted }}>from</span>
              <span style={{ fontFamily: 'monospace', color: p.primary, fontSize: '12px' }}>0x7a25...488d</span>
              <span style={{ color: p.muted }}>→</span>
              <span style={{ fontFamily: 'monospace', color: p.primary, fontSize: '12px' }}>Pool 0x8ad5...1a2b</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 14px', background: p.surface, borderRadius: '8px', fontSize: '13px' }}>
              <span style={{ fontSize: '16px' }}>↑</span>
              <span style={{ fontWeight: 600 }}>25,247 USDC</span>
              <span style={{ color: p.muted }}>from</span>
              <span style={{ fontFamily: 'monospace', color: p.primary, fontSize: '12px' }}>Pool 0x8ad5...1a2b</span>
              <span style={{ color: p.muted }}>→</span>
              <span style={{ fontFamily: 'monospace', color: p.primary, fontSize: '12px' }}>0x7a25...488d</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 14px', background: p.surface, borderRadius: '8px', fontSize: '13px' }}>
              <span style={{ fontSize: '16px' }}>↔</span>
              <span>Swap on Uniswap V3 Pool</span>
              <span style={{ fontFamily: 'monospace', color: p.textSecondary, fontSize: '12px' }}>0x8ad5...1a2b</span>
            </div>
          </div>
        </div>

        {/* From/To */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', fontSize: '13px' }}>
          <div>
            <span style={{ color: p.muted, display: 'block', marginBottom: '4px', fontSize: '12px' }}>From</span>
            <span style={{ fontFamily: 'monospace', color: p.primary }}>0x7a250d5630b4cf539739df2c5dacb4c659f2488d</span>
          </div>
          <div>
            <span style={{ color: p.muted, display: 'block', marginBottom: '4px', fontSize: '12px' }}>To (Safe)</span>
            <span style={{ fontFamily: 'monospace', color: p.primary }}>0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45</span>
          </div>
        </div>
      </div>
    </div>
  )
}
