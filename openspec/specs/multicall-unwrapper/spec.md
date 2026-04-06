## ADDED Requirements

### Requirement: Multicall detection
The Multicall unwrapper SHALL detect transactions whose input starts with known multicall selectors:
- `multicall(bytes[])` — selector `0xac9650d8`
- `multicall(uint256,bytes[])` — selector `0x5ae401dc` (Uniswap V3 variant with deadline)

#### Scenario: Detect multicall(bytes[])
- **WHEN** a transaction has input starting with `0xac9650d8`
- **THEN** the Multicall unwrapper matches

#### Scenario: Detect Uniswap V3 multicall
- **WHEN** a transaction has input starting with `0x5ae401dc`
- **THEN** the Multicall unwrapper matches

### Requirement: Multicall inner call extraction
When a multicall is detected, the unwrapper SHALL decode the `bytes[]` array of inner calls. For each inner call, it SHALL return an operation with:
- `operation_type`: `:multicall_item`
- `operation_index`: sequential index within the transaction
- `from_address`: the original transaction sender
- `to_address`: the multicall contract address (inner calls are self-calls)
- `input`: the inner call's calldata (for the decoder to process)

#### Scenario: Multicall with 3 inner calls
- **WHEN** a multicall transaction contains 3 encoded calls
- **THEN** 3 `:multicall_item` operations are returned with operation_index 0, 1, 2

#### Scenario: Uniswap V3 multicall (approve + swap)
- **WHEN** a Uniswap V3 multicall contains an approve and a swap
- **THEN** two operations are returned: one with approve calldata and one with swap calldata, each independently decodable by the decoder pipeline

#### Scenario: Empty multicall
- **WHEN** a multicall contains an empty bytes array
- **THEN** the unwrapper falls back to a single `:call` operation
