## ADDED Requirements

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
