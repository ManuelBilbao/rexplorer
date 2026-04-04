import { Link } from 'react-router'
import { formatBlockNumber } from '../../lib/format'

interface BlockNumberProps {
  number: number
  chain: string
}

export function BlockNumber({ number, chain }: BlockNumberProps) {
  return (
    <Link
      to={`/${chain}/block/${number}`}
      className="font-mono text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 hover:underline"
    >
      {formatBlockNumber(number)}
    </Link>
  )
}
