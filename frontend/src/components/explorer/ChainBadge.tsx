import Badge from '../ui/Badge'

const CHAIN_COLORS: Record<string, string> = {
  ethereum: 'bg-blue-500',
  polygon: 'bg-purple-500',
  arbitrum: 'bg-sky-500',
  optimism: 'bg-red-500',
  base: 'bg-blue-600',
  avalanche: 'bg-red-600',
  bsc: 'bg-yellow-500',
  bnb: 'bg-yellow-500',
  fantom: 'bg-blue-400',
  gnosis: 'bg-emerald-500',
  zksync: 'bg-indigo-500',
}

const CHAIN_NAMES: Record<string, string> = {
  ethereum: 'Ethereum',
  polygon: 'Polygon',
  arbitrum: 'Arbitrum',
  optimism: 'Optimism',
  base: 'Base',
  avalanche: 'Avalanche',
  bsc: 'BNB Chain',
  bnb: 'BNB Chain',
  fantom: 'Fantom',
  gnosis: 'Gnosis',
  zksync: 'zkSync',
}

interface ChainBadgeProps {
  chain: string | null
}

export function ChainBadge({ chain }: ChainBadgeProps) {
  const key = (chain || '').toLowerCase()
  const dotColor = CHAIN_COLORS[key] || 'bg-rex-text-secondary'
  const name = CHAIN_NAMES[key] || chain || ''

  return (
    <Badge variant="gray">
      <span className="inline-flex items-center gap-1.5">
        <span className={`h-2 w-2 rounded-full ${dotColor}`} />
        {name}
      </span>
    </Badge>
  )
}
