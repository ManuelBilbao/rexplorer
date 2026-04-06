## ADDED Requirements

### Requirement: Interpreter behaviour
The system SHALL define a `Rexplorer.Decoder.Interpreter` behaviour with callbacks:
- `matches?/2` — given a `to_address` and decoded function info, returns whether this interpreter handles it
- `interpret/2` — given the decoded call and transaction context, returns a structured action

Each interpreter MUST return a structured `%Action{}` with `:type`, `:protocol`, and `:params` fields.

#### Scenario: Interpreter matches a known call
- **WHEN** `matches?("0x7a250d5630b4cf539739df2c5dacb4c659f2488d", %{function: "swapExactTokensForTokens"})` is called on the UniswapV2 interpreter
- **THEN** it returns `true`

#### Scenario: Interpreter does not match
- **WHEN** `matches?` is called with an unrelated address
- **THEN** it returns `false`

### Requirement: ERC-20 interpreter
The system SHALL provide an interpreter for ERC-20 `transfer`, `transferFrom`, and `approve` calls. It MUST produce actions of type `:transfer`, `:transfer_from`, or `:approve` with token address, from, to, and amount.

#### Scenario: Interpret ERC-20 transfer
- **WHEN** a decoded `transfer(address,uint256)` call to an ERC-20 contract is interpreted
- **THEN** it returns `%Action{type: :transfer, protocol: "ERC-20", params: %{to: "0x...", amount: 1000000, token: "0x..."}}`

### Requirement: Uniswap V2 interpreter
The system SHALL interpret Uniswap V2 Router swap functions. It MUST produce actions of type `:swap` with token_in, token_out, amount_in, amount_out_min, and the path.

#### Scenario: Interpret Uniswap V2 swap
- **WHEN** a decoded `swapExactTokensForTokens` call is interpreted
- **THEN** it returns `%Action{type: :swap, protocol: "Uniswap V2", params: %{token_in: "0x...", token_out: "0x...", amount_in: ..., amount_out_min: ...}}`

### Requirement: Uniswap V3 interpreter
The system SHALL interpret Uniswap V3 SwapRouter functions (`exactInputSingle`, `exactInput`, `exactOutputSingle`, `exactOutput`). It MUST produce `:swap` actions.

#### Scenario: Interpret Uniswap V3 exactInputSingle
- **WHEN** a decoded `exactInputSingle` call to the V3 router is interpreted
- **THEN** it returns a `:swap` action with token_in, token_out, and amount_in

### Requirement: WETH interpreter
The system SHALL interpret WETH `deposit()` and `withdraw(uint256)` calls. Deposit MUST be interpreted as `:wrap` and withdraw as `:unwrap`.

#### Scenario: Interpret WETH deposit
- **WHEN** a `deposit()` call to a known WETH address is interpreted (with tx value > 0)
- **THEN** it returns `%Action{type: :wrap, protocol: "WETH", params: %{amount: <tx_value>}}`

### Requirement: Aave V3 interpreter
The system SHALL interpret Aave V3 Pool `supply`, `withdraw`, `borrow`, and `repay` calls. Each MUST produce the corresponding action type with asset address and amount.

#### Scenario: Interpret Aave V3 supply
- **WHEN** a decoded `supply(address,uint256,address,uint16)` call is interpreted
- **THEN** it returns `%Action{type: :supply, protocol: "Aave V3", params: %{asset: "0x...", amount: ..., on_behalf_of: "0x..."}}`

### Requirement: Interpreter registry
The system SHALL provide `Rexplorer.Decoder.Interpreter.Registry` that iterates through all registered interpreters and returns the first match. If no interpreter matches, it SHALL return `{:error, :no_interpreter}`.

#### Scenario: Route to correct interpreter
- **WHEN** a decoded Uniswap V3 call is passed to the registry
- **THEN** the UniswapV3 interpreter is selected and returns the action

#### Scenario: No interpreter matches
- **WHEN** a decoded call to an unknown contract is passed to the registry
- **THEN** it returns `{:error, :no_interpreter}`
