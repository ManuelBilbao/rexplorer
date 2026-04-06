import type { ReactNode } from 'react'
import { Link } from 'react-router'

const ADDRESS_PATTERN = /0x[0-9a-fA-F]{40}/g

/**
 * Scans text for full Ethereum addresses (0x + 40 hex chars) and replaces
 * them with truncated, clickable Link components.
 */
export function linkifyAddresses(text: string, chain: string | null): ReactNode[] {
  if (!chain || !text) return [text]

  const parts: ReactNode[] = []
  let lastIndex = 0
  const regex = new RegExp(ADDRESS_PATTERN.source, 'g')
  let match: RegExpExecArray | null

  while ((match = regex.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parts.push(text.slice(lastIndex, match.index))
    }

    const addr = match[0].toLowerCase()
    parts.push(
      <Link
        key={match.index}
        to={`/${chain}/address/${addr}`}
        className="text-rex-primary hover:underline font-mono"
      >
        {addr.slice(0, 6)}...{addr.slice(-4)}
      </Link>
    )

    lastIndex = regex.lastIndex
  }

  if (lastIndex < text.length) {
    parts.push(text.slice(lastIndex))
  }

  return parts.length > 0 ? parts : [text]
}
