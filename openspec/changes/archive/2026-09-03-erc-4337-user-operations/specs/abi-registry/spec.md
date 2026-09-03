## MODIFIED Requirements

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

## ADDED Requirements

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
