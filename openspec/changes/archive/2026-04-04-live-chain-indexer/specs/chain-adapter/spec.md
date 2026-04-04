## ADDED Requirements

### Requirement: Poll interval callback
The `Rexplorer.Chain.Adapter` behaviour SHALL define a new callback `poll_interval_ms/0` that returns the recommended polling interval in milliseconds for the chain. This reflects the chain's block time and MUST be implemented by all adapters.

#### Scenario: Ethereum poll interval
- **WHEN** `Rexplorer.Chain.Ethereum.poll_interval_ms/0` is called
- **THEN** it returns `12_000` (12 seconds, matching Ethereum's ~12s block time)

#### Scenario: L2 poll interval
- **WHEN** an Optimism or Base adapter implements `poll_interval_ms/0`
- **THEN** it returns `2_000` (2 seconds, matching L2 block production)

### Requirement: Token transfer extraction callback
The `Rexplorer.Chain.Adapter` behaviour SHALL define a new callback `extract_token_transfers/1` that takes a transaction map (with logs and value) and returns a list of token transfer attribute maps. Each adapter MUST handle at minimum:

- Native token transfers (from the transaction's `value` field)
- ERC-20 `Transfer(address,address,uint256)` events (topic0 = `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef`)

Adapters MAY handle additional transfer event types (ERC-721, ERC-1155) as needed.

#### Scenario: Ethereum adapter extracts ERC-20 transfer
- **WHEN** `extract_token_transfers/1` is called with a transaction whose logs contain a Transfer event
- **THEN** a token transfer with `token_type: :erc20`, `from_address`, `to_address`, `amount`, and `token_contract_address` is returned

#### Scenario: Ethereum adapter extracts native transfer
- **WHEN** `extract_token_transfers/1` is called with a transaction that has `value > 0`
- **THEN** a token transfer with `token_type: :native` and the transaction's `from_address`, `to_address`, and `value` as amount is returned

#### Scenario: Transaction with no transfers
- **WHEN** `extract_token_transfers/1` is called with a transaction that has `value = 0` and no Transfer events in logs
- **THEN** an empty list is returned

## MODIFIED Requirements

### Requirement: Chain adapter behaviour definition
The system SHALL define an Elixir behaviour `Rexplorer.Chain.Adapter` that all chain implementations MUST implement. The behaviour SHALL define the following callbacks:

- `chain_id/0` — returns the EIP-155 chain ID (integer)
- `chain_type/0` — returns the chain type atom (`:l1`, `:optimistic_rollup`, `:zk_rollup`, `:sidechain`)
- `native_token/0` — returns `{symbol, decimals}` tuple
- `block_fields/0` — returns a list of chain-specific field definitions for the `chain_extra` JSONB column
- `transaction_fields/0` — returns a list of chain-specific field definitions for the `chain_extra` JSONB column
- `extract_operations/1` — given a transaction with decoded data, returns a list of operations (the chain may add chain-specific operation types)
- `bridge_contracts/0` — returns a list of known bridge contract addresses for cross-chain link detection
- `poll_interval_ms/0` — returns the recommended polling interval in milliseconds for live indexing
- `extract_token_transfers/1` — given a transaction map with logs and value, returns a list of token transfer attribute maps

#### Scenario: Adapter implements all required callbacks
- **WHEN** a new chain adapter module is created
- **THEN** the compiler SHALL warn if any required callback is not implemented

#### Scenario: Adapter provides chain-specific block fields
- **WHEN** the Optimism adapter defines `block_fields/0`
- **THEN** it returns field definitions like `[{:l1_block_number, :integer}, {:sequence_number, :integer}]` that describe what goes in `chain_extra`

### Requirement: Ethereum mainnet reference adapter
The system SHALL include a `Rexplorer.Chain.Ethereum` module that implements the `Rexplorer.Chain.Adapter` behaviour for Ethereum mainnet (chain_id: 1). This serves as the reference implementation. It SHALL return an empty list for `block_fields/0` and `transaction_fields/0` (mainnet has no chain-specific extensions). Its `extract_operations/1` SHALL handle standard EOA calls, producing a single `call` operation per transaction. Its `poll_interval_ms/0` SHALL return `12_000`. Its `extract_token_transfers/1` SHALL handle native ETH transfers and ERC-20 Transfer events.

#### Scenario: Ethereum adapter identifies itself
- **WHEN** `Rexplorer.Chain.Ethereum.chain_id/0` is called
- **THEN** it returns `1`

#### Scenario: Ethereum adapter extracts simple operation
- **WHEN** `extract_operations/1` is called with a standard EOA transfer transaction
- **THEN** it returns a list with exactly one operation of type `call`

#### Scenario: Ethereum adapter poll interval
- **WHEN** `Rexplorer.Chain.Ethereum.poll_interval_ms/0` is called
- **THEN** it returns `12_000`
