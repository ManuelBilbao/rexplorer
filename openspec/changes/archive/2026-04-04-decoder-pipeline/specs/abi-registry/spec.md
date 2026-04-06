## ADDED Requirements

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

#### Scenario: Registry contains ERC-20 transfer
- **WHEN** the selector for `transfer(address,uint256)` is looked up
- **THEN** it returns the full ABI definition
