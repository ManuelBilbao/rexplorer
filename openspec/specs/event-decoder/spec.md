## ADDED Requirements

### Requirement: Event signature registry
The ABI registry SHALL be extended to include known event signatures, keyed by topic0 (the Keccak-256 hash of the event signature). The registry MUST support lookup by topic0 and return the event name, parameter names, parameter types, and which parameters are indexed.

#### Scenario: Look up Transfer event
- **WHEN** `lookup_event(transfer_topic0)` is called
- **THEN** it returns the event definition for `Transfer(address indexed from, address indexed to, uint256 value)`

#### Scenario: Unknown event topic
- **WHEN** `lookup_event(unknown_topic0)` is called
- **THEN** it returns `nil`

### Requirement: Built-in event signatures
The registry MUST include event signatures for:
- ERC-20: `Transfer(address,address,uint256)`, `Approval(address,address,uint256)`
- Uniswap V2: `Swap(address,uint256,uint256,uint256,uint256,address)`
- Uniswap V3: `Swap(address,address,int256,int256,uint160,uint128,int24)`
- Aave V3: `Supply(address,address,address,uint256,uint16)`, `Withdraw(address,address,address,uint256)`, `Borrow(address,address,address,uint256,uint8,uint256,uint16)`, `Repay(address,address,address,uint256,bool)`
- WETH: `Deposit(address,uint256)`, `Withdrawal(address,uint256)`

#### Scenario: Registry contains Uniswap V3 Swap event
- **WHEN** the topic0 for the Uniswap V3 Swap event is looked up
- **THEN** it returns the full event definition with parameter names and types

### Requirement: Log decoding
The system SHALL provide `Rexplorer.Decoder.EventDecoder.decode_log/1` that takes a log (with topic0-3 and data) and returns a decoded map with event name, decoded parameters (indexed from topics, non-indexed from data), and a human-readable summary string.

#### Scenario: Decode ERC-20 Transfer event
- **WHEN** a log with Transfer topic0 is decoded
- **THEN** it returns `%{event: "Transfer", params: %{from: "0x...", to: "0x...", value: 1000000}, summary: "Transfer 1,000 USDC from 0x7a25...488d to 0x3075...7d31"}`

#### Scenario: Decode unknown event
- **WHEN** a log with unknown topic0 is decoded
- **THEN** it returns `nil` (not decoded)

### Requirement: Decoded log persistence
The decoder worker SHALL process logs alongside operations. For each log in a transaction, it SHALL attempt to decode the event and write the result into the `logs.decoded` JSONB column. The decoded JSONB MUST contain at minimum: `event_name` (string), `params` (map of decoded parameters), and `summary` (human-readable string).

#### Scenario: Log decoded and persisted
- **WHEN** the decoder worker processes a transaction's logs
- **THEN** known events have their `decoded` JSONB populated with event name, params, and summary

#### Scenario: Unknown log left as null
- **WHEN** a log has an unrecognized topic0
- **THEN** its `decoded` field remains null
