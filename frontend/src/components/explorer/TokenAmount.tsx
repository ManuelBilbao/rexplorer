import { formatAmount } from '../../lib/format'

interface TokenAmountProps {
  value: string
  symbol: string
  decimals: number
}

export function TokenAmount({ value, symbol, decimals }: TokenAmountProps) {
  return (
    <span className="font-mono text-rex-text" title={value}>
      {formatAmount(value, decimals, symbol)}
    </span>
  )
}
