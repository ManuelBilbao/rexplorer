import { Link, useParams, useLocation } from 'react-router'

const CHAIN_NAMES: Record<string, string> = {
  ethereum: 'Ethereum',
  optimism: 'Optimism',
  base: 'Base',
  bnb: 'BNB Chain',
  polygon: 'Polygon',
}

export function Breadcrumb() {
  const { chain, hash, number } = useParams()
  const location = useLocation()

  if (!chain) return null

  const chainName = CHAIN_NAMES[chain] || chain
  const segments = buildSegments(chain, chainName, location.pathname, hash, number)

  if (segments.length <= 1) return null

  return (
    <nav className="flex items-center gap-1.5 text-xs text-rex-text-secondary mb-4">
      {segments.map((seg, i) => (
        <span key={i} className="flex items-center gap-1.5">
          {i > 0 && <span className="text-rex-border">›</span>}
          {seg.link && i < segments.length - 1 ? (
            <Link to={seg.link} className="hover:text-rex-primary transition-colors">
              {seg.label}
            </Link>
          ) : (
            <span className={i === segments.length - 1 ? 'text-rex-text font-medium' : ''}>
              {seg.label}
            </span>
          )}
        </span>
      ))}
    </nav>
  )
}

interface Segment {
  label: string
  link?: string
}

function buildSegments(chain: string, chainName: string, path: string, hash?: string, number?: string): Segment[] {
  const segments: Segment[] = [
    { label: chainName, link: `/${chain}` },
  ]

  if (path.includes('/tx/')) {
    segments.push({ label: 'Transaction' })
    if (hash) {
      segments.push({ label: `${hash.slice(0, 10)}...${hash.slice(-6)}` })
    }
  } else if (path.includes('/block/')) {
    segments.push({ label: 'Blocks', link: `/${chain}/blocks` })
    if (number) {
      segments.push({ label: `#${Number(number).toLocaleString()}` })
    }
  } else if (path.includes('/blocks')) {
    segments.push({ label: 'Blocks' })
  } else if (path.includes('/address/')) {
    segments.push({ label: 'Address' })
    if (hash) {
      segments.push({ label: `${hash.slice(0, 10)}...${hash.slice(-6)}` })
    }
  }

  return segments
}
