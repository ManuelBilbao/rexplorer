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
        className="font-mono text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 hover:underline"
        title={hash}
      >
        {formatAddress(hash)}
      </Link>
      <CopyButton value={hash} />
    </span>
  )
}
