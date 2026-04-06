import { Link } from 'react-router'
import { formatAddress } from '../../lib/format'
import { CopyButton } from './CopyButton'

interface AddressDisplayProps {
  address: string
  label?: string
  chain: string
}

export function AddressDisplay({ address, label, chain }: AddressDisplayProps) {
  const display = label || formatAddress(address)

  return (
    <span className="inline-flex items-center gap-1">
      <Link
        to={`/${chain}/address/${address}`}
        className="font-mono text-rex-primary hover:opacity-80 hover:underline"
        title={address}
      >
        {display}
      </Link>
      <CopyButton value={address} />
    </span>
  )
}
