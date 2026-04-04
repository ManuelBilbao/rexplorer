defmodule RexplorerWeb.Schemas do
  @moduledoc "OpenAPI schema definitions for the Rexplorer public API."

  alias OpenApiSpex.Schema

  defmodule ErrorResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "ErrorResponse",
      type: :object,
      properties: %{
        error: %Schema{type: :string, description: "Error code", example: "not_found"},
        message: %Schema{type: :string, description: "Human-readable error message"}
      },
      required: [:error, :message]
    })
  end

  defmodule Chain do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Chain",
      type: :object,
      properties: %{
        chain_id: %Schema{type: :integer, description: "EIP-155 chain ID", example: 1},
        name: %Schema{type: :string, example: "Ethereum"},
        chain_type: %Schema{type: :string, enum: ["l1", "optimistic_rollup", "zk_rollup", "sidechain"]},
        native_token_symbol: %Schema{type: :string, example: "ETH"},
        explorer_slug: %Schema{type: :string, example: "ethereum"}
      },
      required: [:chain_id, :name, :chain_type, :native_token_symbol, :explorer_slug]
    })
  end

  defmodule ChainListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "ChainListResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: Chain}
      }
    })
  end

  defmodule ChainResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "ChainResponse",
      type: :object,
      properties: %{
        data: Chain
      }
    })
  end

  defmodule Block do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Block",
      type: :object,
      properties: %{
        block_number: %Schema{type: :integer, example: 20_000_000},
        hash: %Schema{type: :string, example: "0xabc..."},
        parent_hash: %Schema{type: :string},
        timestamp: %Schema{type: :string, format: :"date-time"},
        gas_used: %Schema{type: :integer},
        gas_limit: %Schema{type: :integer},
        base_fee_per_gas: %Schema{type: :integer, nullable: true},
        transaction_count: %Schema{type: :integer},
        chain_extra: %Schema{type: :object, additionalProperties: true}
      }
    })
  end

  defmodule BlockListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "BlockListResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: Block},
        next_cursor: %Schema{type: :integer, nullable: true, description: "Block number cursor for next page"}
      }
    })
  end

  defmodule BlockResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "BlockResponse",
      type: :object,
      properties: %{
        data: Block
      }
    })
  end

  defmodule Transaction do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Transaction",
      type: :object,
      properties: %{
        hash: %Schema{type: :string, example: "0xabc..."},
        from_address: %Schema{type: :string},
        to_address: %Schema{type: :string, nullable: true},
        value: %Schema{type: :string, description: "Wei value as decimal string"},
        gas_price: %Schema{type: :integer, nullable: true},
        gas_used: %Schema{type: :integer, nullable: true},
        nonce: %Schema{type: :integer},
        status: %Schema{type: :boolean, nullable: true},
        transaction_type: %Schema{type: :integer, nullable: true},
        transaction_index: %Schema{type: :integer},
        block_number: %Schema{type: :integer, nullable: true},
        chain_extra: %Schema{type: :object, additionalProperties: true}
      }
    })
  end

  defmodule TransactionListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TransactionListResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: Transaction},
        next_cursor: %Schema{type: :object, nullable: true, description: "Cursor with before_block and before_index"}
      }
    })
  end

  defmodule TransactionResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TransactionResponse",
      type: :object,
      properties: %{
        data: Transaction
      }
    })
  end

  defmodule Operation do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Operation",
      type: :object,
      properties: %{
        operation_type: %Schema{type: :string, enum: ["call", "user_operation", "multisig_execution", "multicall_item", "delegate_call"]},
        operation_index: %Schema{type: :integer},
        from_address: %Schema{type: :string},
        to_address: %Schema{type: :string, nullable: true},
        value: %Schema{type: :string, description: "Wei value as decimal string"},
        decoded_summary: %Schema{type: :string, nullable: true, description: "Human-readable description of what this operation did"}
      }
    })
  end

  defmodule OperationListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "OperationListResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: Operation}
      }
    })
  end

  defmodule Address do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Address",
      type: :object,
      properties: %{
        hash: %Schema{type: :string, example: "0xabc..."},
        is_contract: %Schema{type: :boolean},
        label: %Schema{type: :string, nullable: true},
        first_seen_at: %Schema{type: :string, format: :"date-time"}
      }
    })
  end

  defmodule AddressResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "AddressResponse",
      type: :object,
      properties: %{
        data: Address
      }
    })
  end

  defmodule TokenTransfer do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TokenTransfer",
      type: :object,
      properties: %{
        from_address: %Schema{type: :string},
        to_address: %Schema{type: :string},
        token_contract_address: %Schema{type: :string},
        amount: %Schema{type: :string, description: "Raw amount as decimal string"},
        token_type: %Schema{type: :string, enum: ["native", "erc20", "erc721", "erc1155"]},
        token_id: %Schema{type: :string, nullable: true}
      }
    })
  end

  defmodule TokenTransferListResponse do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "TokenTransferListResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: TokenTransfer},
        next_cursor: %Schema{type: :integer, nullable: true, description: "ID cursor for next page"}
      }
    })
  end
end
