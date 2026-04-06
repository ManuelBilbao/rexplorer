## ADDED Requirements

### Requirement: Safe execTransaction detection
The Safe unwrapper SHALL detect transactions whose input calldata starts with the `execTransaction` selector (`0x6a761202`). Detection MUST be selector-based (not address-based) since Safe proxies are deployed at arbitrary addresses.

#### Scenario: Detect Safe execution
- **WHEN** a transaction has input starting with `0x6a761202`
- **THEN** the Safe unwrapper matches

#### Scenario: Non-Safe transaction
- **WHEN** a transaction has a different function selector
- **THEN** the Safe unwrapper does not match

### Requirement: Safe inner call extraction
When a Safe `execTransaction` is detected, the unwrapper SHALL decode the calldata to extract `to` (inner target), `value` (inner ETH value), `data` (inner calldata), and `operation` (0 = call, 1 = delegatecall). It SHALL return a single operation with:
- `operation_type`: `:multisig_execution`
- `from_address`: the Safe contract address (the `to_address` of the outer transaction)
- `to_address`: the inner target address
- `value`: the inner value
- `input`: the inner calldata (for the decoder to process)

#### Scenario: Safe wrapping a token transfer
- **WHEN** a Safe calls `execTransaction` with inner data being an ERC-20 `transfer`
- **THEN** one `:multisig_execution` operation is returned with `from_address` = Safe address and `input` = the ERC-20 transfer calldata

#### Scenario: Safe wrapping a swap
- **WHEN** a Safe calls `execTransaction` with inner data being a Uniswap swap
- **THEN** one `:multisig_execution` operation is returned with the swap calldata as `input`, which the decoder can then interpret as "Swapped X for Y on Uniswap"

#### Scenario: Safe delegatecall (operation = 1)
- **WHEN** the `operation` parameter is 1 (delegatecall)
- **THEN** the operation_type is `:delegate_call` instead of `:multisig_execution`
