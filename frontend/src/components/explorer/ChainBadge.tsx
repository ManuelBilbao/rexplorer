const CHAIN_COLORS: Record<string, string> = {
  ethereum: 'bg-blue-500',
  polygon: 'bg-purple-500',
  arbitrum: 'bg-sky-500',
  optimism: 'bg-red-500',
  base: 'bg-blue-600',
  avalanche: 'bg-red-600',
  bsc: 'bg-yellow-500',
  fantom: 'bg-blue-400',
  gnosis: 'bg-emerald-500',
  zksync: 'bg-indigo-500',
}

interface ChainBadgeProps {
  chain: string
}

export function ChainBadge({ chain }: ChainBadgeProps) {
  const dotColor = CHAIN_COLORS[chain.toLowerCase()] || 'bg-gray-400'

  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-700 dark:text-gray-300">
      <span className={`h-2 w-2 rounded-full ${dotColor}`} />
      {chain}
    </span>
  )
}
