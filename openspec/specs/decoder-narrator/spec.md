## Purpose

Turns a semantic action into the sentence a person actually reads.

## Requirements

### Requirement: Action narration
The system SHALL provide `Rexplorer.Decoder.Narrator.narrate/2` that takes an `%Action{}` struct and a context (containing chain_id for token resolution) and returns a human-readable string.

#### Scenario: Narrate a swap
- **WHEN** narrate is called with `%Action{type: :swap, protocol: "Uniswap V3", params: %{token_in: weth_addr, token_out: usdc_addr, amount_in: 10000000000000000000}}`
- **THEN** it returns `"Swapped 10 ETH for USDC on Uniswap V3"` (resolving token symbols from the token registry)

#### Scenario: Narrate an ERC-20 transfer
- **WHEN** narrate is called with a `:transfer` action
- **THEN** it returns `"Transferred 1,000 USDC to 0x7a25...488d"`

#### Scenario: Narrate WETH wrap
- **WHEN** narrate is called with a `:wrap` action
- **THEN** it returns `"Wrapped 10 ETH to WETH"`

#### Scenario: Narrate Aave supply
- **WHEN** narrate is called with a `:supply` action
- **THEN** it returns `"Supplied 1,000 USDC to Aave V3"`

### Requirement: Token resolution
The narrator MUST resolve token contract addresses to human-readable symbols using the `tokens` and `token_addresses` tables. If a token is not in the registry, the narrator MUST fall back to displaying the truncated contract address.

#### Scenario: Known token resolved
- **WHEN** the narrator encounters the USDC contract address on Ethereum
- **THEN** it displays "USDC" instead of "0xa0b8..."

#### Scenario: Unknown token fallback
- **WHEN** the narrator encounters an unknown token address
- **THEN** it displays the truncated address "0xa0b8...eb48"

### Requirement: Amount formatting
The narrator MUST format token amounts by dividing the raw value by `10^decimals` and applying thousand separators. It MUST avoid unnecessary decimal places (show "10 ETH" not "10.000000 ETH").

#### Scenario: Format large amount
- **WHEN** a raw amount of 25000000000 with 6 decimals (USDC) is formatted
- **THEN** it displays "25,000"

#### Scenario: Format fractional amount
- **WHEN** a raw amount of 1500000000000000000 with 18 decimals (ETH) is formatted
- **THEN** it displays "1.5"

### Requirement: Fallback narration
If no interpreter matched the operation (unknown contract/function), the narrator MUST produce a generic summary using the decoded function name if available, or "Called 0x... on 0x..." if not.

#### Scenario: Known function, unknown protocol
- **WHEN** the function was decoded as `doSomething(uint256)` but no interpreter matched
- **THEN** the summary is `"Called doSomething on 0x68b3...fc45"`

#### Scenario: Completely unknown
- **WHEN** neither the selector nor the contract are recognized
- **THEN** the summary is `"Called 0x38ed1739 on 0x68b3...fc45"`

### Requirement: UserOperation narration
An operation of type `user_operation` SHALL be narrated with the smart account as the actor, so the summary describes what the account did rather than what the bundler called. When the operation was sponsored, the summary MUST end with a clause naming the paymaster. When the UserOperation deployed its account, the summary MUST say so. When the UserOperation failed, the summary MUST say that too, rather than reading as though the action succeeded.

#### Scenario: Sponsored swap
- **WHEN** a `user_operation` operation wrapping a Uniswap swap has a paymaster
- **THEN** the summary reads like "Smart account 0xabc… swapped 10 ETH for 25,000 USDC on Uniswap V3 (gas paid by paymaster 0xdef…)"

#### Scenario: Self-funded operation
- **WHEN** the same operation has no paymaster
- **THEN** the summary is the same sentence without the sponsorship clause

#### Scenario: Account deployment
- **WHEN** a `user_operation` operation carries a factory
- **THEN** the summary states that the smart account was deployed as part of the operation

#### Scenario: Failed UserOperation
- **WHEN** a `user_operation` operation's recorded outcome is unsuccessful
- **THEN** the summary marks it as failed

#### Scenario: Undecodable inner call
- **WHEN** the UserOperation's inner call has no known selector
- **THEN** the summary still names the smart account and the target, falling back the same way any other operation does
