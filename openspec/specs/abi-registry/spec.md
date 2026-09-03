## Purpose

Turns raw EVM calldata and event logs into named functions and typed parameters, from a registry of known selectors and event signatures.

## Requirements

### Requirement: Function selector lookup
The system SHALL provide `Rexplorer.Decoder.ABI.lookup_selector/1` that takes a 4-byte function selector and returns the matching ABI function definition (name, inputs, outputs) from the built-in registry. If no match is found, it SHALL return `nil`.

#### Scenario: Known selector
- **WHEN** `lookup_selector(<<0x38, 0xED, 0x17, 0x39>>)` is called
- **THEN** it returns the ABI definition for `swapExactTokensForTokens(uint256,uint256,address[],address,uint256)`

#### Scenario: Unknown selector
- **WHEN** `lookup_selector(<<0xFF, 0xFF, 0xFF, 0xFF>>)` is called with an unregistered selector
- **THEN** it returns `nil`

### Requirement: Calldata decoding
The system SHALL provide `Rexplorer.Decoder.ABI.decode_calldata/2` that takes raw calldata (binary) and an ABI function definition, and returns a map of decoded parameter names to values. Uint256 values MUST be returned as integers. Address values MUST be returned as lowercase hex strings. Bytes values MUST be returned as hex strings.

#### Scenario: Decode ERC-20 transfer
- **WHEN** calldata for `transfer(address,uint256)` is decoded
- **THEN** the result contains `%{"to" => "0xabc...", "amount" => 1000000}`

### Requirement: Full calldata decode from selector
The system SHALL provide `Rexplorer.Decoder.ABI.decode/1` that takes raw calldata, extracts the 4-byte selector, looks it up in the registry, and decodes the parameters. Returns `{:ok, %{function: name, params: map}}` or `{:error, :unknown_selector}`.

#### Scenario: Decode known calldata
- **WHEN** `decode(calldata)` is called with an ERC-20 `transfer` calldata
- **THEN** it returns `{:ok, %{function: "transfer", params: %{"to" => "0x...", "amount" => ...}}}`

#### Scenario: Decode unknown calldata
- **WHEN** `decode(calldata)` is called with an unknown function selector
- **THEN** it returns `{:error, :unknown_selector}`

### Requirement: Built-in protocol ABIs
The registry MUST include ABI definitions for:
- ERC-20: `transfer`, `transferFrom`, `approve`
- Uniswap V2 Router: `swapExactTokensForTokens`, `swapTokensForExactTokens`, `swapExactETHForTokens`, `swapETHForExactTokens`
- Uniswap V3 Router: `exactInputSingle`, `exactInput`, `exactOutputSingle`, `exactOutput`
- WETH: `deposit`, `withdraw`
- Aave V3 Pool: `supply`, `withdraw`, `borrow`, `repay`
- Safe: `execTransaction`
- Multicall: `multicall(bytes[])`, `multicall(uint256,bytes[])`
- ERC-4337 EntryPoint: `handleOps` in both its unpacked (v0.6) and packed (v0.7/v0.8) forms
- ERC-4337 smart accounts: `execute(address,uint256,bytes)`, `executeBatch(address[],bytes[])`, `executeBatch(address[],uint256[],bytes[])`

#### Scenario: Registry contains ERC-20 transfer
- **WHEN** the selector for `transfer(address,uint256)` is looked up
- **THEN** it returns the full ABI definition

#### Scenario: Both EntryPoint shapes registered
- **WHEN** the selectors for the unpacked and packed `handleOps` are looked up
- **THEN** each returns its own definition, distinguishable by the operations array's tuple shape

#### Scenario: Account execution registered
- **WHEN** the selector for `execute(address,uint256,bytes)` is looked up
- **THEN** it returns a definition whose parameters are named `dest`, `value` and `func`

### Requirement: UserOperationEvent decoding
The registry MUST include the ERC-4337 `UserOperationEvent(bytes32,address,address,uint256,bool,uint256,uint256)` event, with `userOpHash`, `sender` and `paymaster` marked indexed and `nonce`, `success`, `actualGasCost`, `actualGasUsed` read from the data section. Decoding it MUST yield those values for both consumers: the unwrapper that correlates events to UserOperations, and the event decoder that renders the Effects section.

#### Scenario: Event looked up by topic
- **WHEN** a log's topic0 is the `UserOperationEvent` signature hash
- **THEN** the registry returns the event definition

#### Scenario: Indexed and data parameters separated
- **WHEN** a `UserOperationEvent` log is decoded
- **THEN** userOpHash, sender and paymaster come from the topics and success and gas cost come from the data

#### Scenario: Advanced user reads the raw event
- **WHEN** a developer inspects the event logs of a bundle
- **THEN** the `UserOperationEvent` entries are decoded rather than shown as raw topics
