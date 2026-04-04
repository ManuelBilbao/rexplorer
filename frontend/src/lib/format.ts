export function formatAddress(address: string, chars = 6): string {
  if (address.length <= chars * 2 + 2) return address
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`
}

export function formatBlockNumber(n: number): string {
  return n.toLocaleString()
}

export function formatAmount(raw: string, decimals: number, symbol?: string): string {
  const value = Number(raw) / 10 ** decimals
  const formatted = value.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 6,
  })
  return symbol ? `${formatted} ${symbol}` : formatted
}

export function formatGas(gas: number): string {
  return gas.toLocaleString()
}

export function formatTimestamp(iso: string): string {
  return new Date(iso).toLocaleString()
}

export function timeAgo(iso: string): string {
  const seconds = Math.floor((Date.now() - new Date(iso).getTime()) / 1000)
  if (seconds < 60) return `${seconds}s ago`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}
