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
      className="font-mono text-rex-primary hover:opacity-80 hover:underline"
    >
      {formatBlockNumber(number)}
    </Link>
  )
}
