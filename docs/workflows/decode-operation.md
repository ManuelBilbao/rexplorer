# Decode Operation Workflow

## Overview

This workflow shows how the decoder worker processes an operation's calldata into a human-readable summary.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Worker as Decoder Worker
    participant DB as PostgreSQL
    participant Pipeline as Pipeline
    participant ABI as ABI Registry (ETS)
    participant Registry as Interpreter Registry
    participant Interp as Protocol Interpreter
    participant Narrator as Narrator
    participant Tokens as Token Tables

    Worker->>DB: SELECT operations WHERE decoder_version IS NULL LIMIT 100
    DB-->>Worker: batch of 100 operations

    Worker->>Tokens: build_token_cache(chain_id)
    Tokens-->>Worker: %{"0xa0b8..." => %{symbol: "USDC", decimals: 6}}

    loop For each operation in batch
        Worker->>Pipeline: decode_operation(op, token_cache)

        Pipeline->>ABI: decode(calldata)
        ABI->>ABI: extract 4-byte selector
        ABI->>ABI: ETS lookup → function definition
        ABI->>ABI: ABI.decode(selector, params_data)
        ABI-->>Pipeline: {:ok, %{function: "transfer", params: %{to: ..., value: ...}}}

        Pipeline->>Registry: interpret(to_address, decoded, tx_context, chain_id)
        Registry->>Registry: iterate interpreters, find first match
        Registry->>Interp: ERC20.interpret(decoded, tx_context, chain_id)
        Interp-->>Registry: {:ok, %Action{type: :transfer, ...}}
        Registry-->>Pipeline: {:ok, action}

        Pipeline->>Narrator: narrate(action, token_cache)
        Narrator->>Narrator: resolve token symbol (USDC)
        Narrator->>Narrator: format amount (1000000 / 10^6 = 1,000)
        Narrator-->>Pipeline: "Transferred 1,000 USDC to 0x7a25...488d"

        Pipeline-->>Worker: {:ok, "Transferred 1,000 USDC to 0x7a25...488d"}
    end

    Worker->>DB: UPDATE operations SET decoded_summary, decoder_version (batch)
```

## Error Handling

- **Unknown selector:** Pipeline returns a fallback string like "Called 0x38ed on 0x68b3..."
- **No interpreter match:** Pipeline returns "Called transfer on 0x68b3..." (function name known, protocol unknown)
- **Decode exception:** Worker catches error, sets `decoder_version` to current (prevents retry), leaves `decoded_summary` as nil
