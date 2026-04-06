import { Link } from 'react-router'
import { formatAddress } from '../../lib/format'
import { CopyButton } from './CopyButton'

interface TxHashProps {
  hash: string
  chain: string
}

export function TxHash({ hash, chain }: TxHashProps) {
  return (
    <span className="inline-flex items-center gap-1">
      <Link
        to={`/${chain}/tx/${hash}`}
        className="font-mono text-rex-primary hover:opacity-80 hover:underline"
        title={hash}
      >
        {formatAddress(hash)}
      </Link>
      <CopyButton value={hash} />
    </span>
  )
}
