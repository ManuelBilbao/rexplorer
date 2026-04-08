import { useQuery } from '@tanstack/react-query'
import { fetchApi } from './client'
import type { Chain, Block, HomeData, TxDetail, AddressOverview, SearchResult, PaginatedResponse, Transaction, BalanceHistoryEntry, TokenTransfer, InternalTransaction } from './types'

export function useChains() {
  return useQuery({
    queryKey: ['chains'],
    queryFn: () => fetchApi<{ data: Chain[] }>('/api/v1/chains').then(r => r.data),
  })
}

export function useBlock(chain: string | null, number: string | undefined) {
  return useQuery({
    queryKey: ['block', chain, number],
    queryFn: () => fetchApi<{ data: Block }>(`/api/v1/chains/${chain}/blocks/${number}`).then(r => r.data),
    enabled: !!chain && !!number,
  })
}

export function useBlocks(chain: string | null, before?: number) {
  const params = new URLSearchParams()
  if (before) params.set('before', String(before))
  params.set('limit', '25')
  const qs = params.toString()

  return useQuery({
    queryKey: ['blocks', chain, before],
    queryFn: () => fetchApi<PaginatedResponse<Block>>(`/api/v1/chains/${chain}/blocks?${qs}`),
    enabled: !!chain,
  })
}

export function useTransactions(chain: string | null, opts?: { address?: string; blockNumber?: number; beforeBlock?: number }) {
  const params = new URLSearchParams({ limit: '25' })
  if (opts?.address) params.set('address', opts.address)
  if (opts?.blockNumber) params.set('block_number', String(opts.blockNumber))
  if (opts?.beforeBlock) params.set('before_block', String(opts.beforeBlock))
  const qs = params.toString()

  return useQuery({
    queryKey: ['transactions', chain, opts],
    queryFn: () => fetchApi<PaginatedResponse<Transaction>>(`/api/v1/chains/${chain}/transactions?${qs}`),
    enabled: !!chain,
  })
}

export function useHomeData(chain: string | null) {
  return useQuery({
    queryKey: ['home', chain],
    queryFn: () => fetchApi<HomeData>(`/internal/chains/${chain}/home`),
    enabled: !!chain,
  })
}

export function useTxDetail(chain: string | null, hash: string | undefined) {
  return useQuery({
    queryKey: ['txDetail', chain, hash],
    queryFn: () => fetchApi<TxDetail>(`/internal/chains/${chain}/transactions/${hash}`),
    enabled: !!chain && !!hash,
  })
}

export function useAddressOverview(chain: string | null, hash: string | undefined) {
  return useQuery({
    queryKey: ['addressOverview', chain, hash],
    queryFn: () => fetchApi<AddressOverview>(`/internal/chains/${chain}/addresses/${hash}`),
    enabled: !!chain && !!hash,
  })
}

export function useBalanceHistory(chain: string | null, hash: string | undefined) {
  return useQuery({
    queryKey: ['balanceHistory', chain, hash],
    queryFn: () => fetchApi<{ data: BalanceHistoryEntry[]; next_cursor: number | null }>(
      `/internal/chains/${chain}/addresses/${hash}/balance-history`
    ),
    enabled: !!chain && !!hash,
  })
}

export function useAddressTokenTransfers(chain: string | null, hash: string | undefined, before?: number) {
  const params = new URLSearchParams({ limit: '25' })
  if (before) params.set('before', String(before))
  const qs = params.toString()

  return useQuery({
    queryKey: ['addressTokenTransfers', chain, hash, before],
    queryFn: () => fetchApi<PaginatedResponse<TokenTransfer>>(
      `/api/v1/chains/${chain}/addresses/${hash}/token-transfers?${qs}`
    ),
    enabled: !!chain && !!hash,
  })
}

export function useAddressInternalTransactions(chain: string | null, hash: string | undefined, before?: number) {
  const params = new URLSearchParams({ limit: '25' })
  if (before) params.set('before', String(before))
  const qs = params.toString()

  return useQuery({
    queryKey: ['addressInternalTxs', chain, hash, before],
    queryFn: () => fetchApi<PaginatedResponse<InternalTransaction>>(
      `/internal/chains/${chain}/addresses/${hash}/internal-transactions?${qs}`
    ),
    enabled: !!chain && !!hash,
  })
}

export function useSearch(query: string, chain?: string | null) {
  const params = new URLSearchParams({ q: query })
  if (chain) params.set('chain', chain)

  return useQuery({
    queryKey: ['search', query, chain],
    queryFn: () => fetchApi<SearchResult>(`/internal/search?${params}`),
    enabled: query.length > 2,
  })
}
