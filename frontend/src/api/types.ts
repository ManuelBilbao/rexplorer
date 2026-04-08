export interface Chain {
  chain_id: number
  name: string
  chain_type: string
  native_token_symbol: string
  explorer_slug: string
}

export interface Block {
  block_number: number
  hash: string
  parent_hash: string
  timestamp: string
  gas_used: number
  gas_limit: number
  base_fee_per_gas: number | null
  transaction_count: number
  chain_extra: Record<string, unknown>
}

export interface Transaction {
  hash: string
  from_address: string
  to_address: string | null
  value: string
  gas_price: number | null
  gas_used: number | null
  nonce: number
  status: boolean | null
  transaction_type: number | null
  transaction_index: number
  block_number: number | null
  chain_extra: Record<string, unknown>
}

export interface Operation {
  operation_type: string
  operation_index: number
  from_address: string
  to_address: string | null
  value: string
  decoded_summary: string | null
}

export interface TokenTransfer {
  from_address: string
  to_address: string
  token_contract_address: string
  amount: string
  token_type: string
  token_id: string | null
}

export interface Address {
  hash: string
  is_contract: boolean
  label: string | null
  first_seen_at: string
  balance_wei: string | null
}

export interface BalanceHistoryEntry {
  block_number: number
  balance_wei: string
  timestamp: string
}

export interface InternalTransaction {
  transaction_hash: string
  block_number: number
  trace_index: number
  from_address: string
  to_address: string | null
  value: string
  call_type: string
  trace_address: number[]
}

export interface CrossChainLink {
  source_chain_id: number
  source_tx_hash: string
  destination_chain_id: number
  destination_tx_hash: string | null
  link_type: string
  status: string
  message_hash: string
}

export interface Log {
  log_index: number
  contract_address: string
  topic0: string | null
  topic1: string | null
  topic2: string | null
  topic3: string | null
  decoded: Record<string, unknown> | null
}

export interface HomeData {
  chain: { chain_id: number; name: string; explorer_slug: string }
  latest_blocks: Block[]
  latest_transactions: Transaction[]
}

export interface TxDetail {
  transaction: Transaction & { block_timestamp: string }
  operations: Operation[]
  token_transfers: TokenTransfer[]
  logs: Log[]
  cross_chain_links: CrossChainLink[]
}

export interface AddressOverview {
  address: Address
  recent_transactions: Transaction[]
  recent_token_transfers: TokenTransfer[]
}

export interface SearchResult {
  type: 'transaction' | 'address' | 'block_number' | 'unknown'
  results: Array<Record<string, unknown>>
}

export interface PaginatedResponse<T> {
  data: T[]
  next_cursor: unknown | null
}
