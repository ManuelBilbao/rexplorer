import { Link } from 'react-router'
import { useChains } from '../api/queries'

const CHAIN_COLORS: Record<string, string> = {
  ethereum: 'bg-blue-500',
  optimism: 'bg-red-500',
  base: 'bg-blue-600',
  bnb: 'bg-yellow-500',
  polygon: 'bg-purple-500',
}

export function LandingPage() {
  const { data: chains, isLoading } = useChains()

  return (
    <div className="max-w-2xl mx-auto py-16">
      <h1 className="text-4xl font-bold text-center mb-2 text-rex-text dark:text-rex-text-dark">
        rexplorer
      </h1>
      <p className="text-center text-rex-text-secondary dark:text-rex-text-secondary-dark mb-12">
        Multi-chain blockchain explorer
      </p>

      {isLoading ? (
        <div className="grid gap-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-16 rounded-lg bg-rex-bg-tertiary dark:bg-rex-bg-tertiary-dark animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="grid gap-4">
          {chains?.map(chain => (
            <Link
              key={chain.chain_id}
              to={`/${chain.explorer_slug}`}
              className="flex items-center gap-4 p-4 rounded-lg border border-rex-border dark:border-rex-border-dark hover:bg-rex-bg-secondary dark:hover:bg-rex-bg-secondary-dark transition-colors"
            >
              <div className={`w-3 h-3 rounded-full ${CHAIN_COLORS[chain.explorer_slug] || 'bg-gray-500'}`} />
              <div>
                <div className="font-semibold text-rex-text dark:text-rex-text-dark">{chain.name}</div>
                <div className="text-sm text-rex-text-secondary dark:text-rex-text-secondary-dark">
                  {chain.native_token_symbol} &middot; {chain.chain_type.replace('_', ' ')}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
