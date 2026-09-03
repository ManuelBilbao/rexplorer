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

/**
 * Structured facts an operation carries that have no column of their own.
 * Empty for a plain call; ERC-4337 operations carry the fields below, and a
 * key is absent rather than null when it does not apply.
 */
export interface OpExtra {
  user_op_hash?: string
  /** Position in the bundle. Operations from one batched UserOperation share it. */
  user_op_index?: number
  entry_point?: string
  entry_point_version?: string
  /** Absent when the UserOperation was self-funded. */
  paymaster?: string
  /** Present when the UserOperation deployed its smart account. */
  factory?: string
  /** This UserOperation's own outcome, independent of the transaction's. */
  success?: boolean
  actual_gas_cost?: string
}

export interface Operation {
  operation_type: string
  operation_index: number
  from_address: string
  to_address: string | null
  value: string
  decoded_summary: string | null
  op_extra: OpExtra
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
  frame_index: number | null
}

export interface Frame {
  frame_index: number
  mode: number
  target: string | null
  gas_limit: number | null
  gas_used: number | null
  status: boolean | null
}

export interface HomeData {
  chain: { chain_id: number; name: string; explorer_slug: string }
  latest_blocks: Block[]
  latest_transactions: Transaction[]
}

export interface TxDetail {
  transaction: Transaction & { block_timestamp: string; payer: string | null }
  operations: (Operation & { frame_index: number | null })[]
  token_transfers: (TokenTransfer & { frame_index: number | null })[]
  logs: Log[]
  cross_chain_links: CrossChainLink[]
  frames: Frame[]
}

export interface AddressOverview {
  address: Address
  recent_transactions: Transaction[]
  recent_token_transfers: TokenTransfer[]
}

export interface SearchResult {
  type: 'transaction' | 'user_operation' | 'address' | 'block_number' | 'unknown'
  results: Array<Record<string, unknown>>
  /** Set when the query resolves to a single place to go. */
  redirect?: string | null
}

export interface PaginatedResponse<T> {
  data: T[]
  next_cursor: unknown | null
}
