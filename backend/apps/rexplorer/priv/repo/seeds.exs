alias Rexplorer.{Repo, Schema.Chain}

chains = [
  %{
    chain_id: 1,
    name: "Ethereum",
    chain_type: :l1,
    native_token_symbol: "ETH",
    explorer_slug: "ethereum"
  },
  %{
    chain_id: 10,
    name: "Optimism",
    chain_type: :optimistic_rollup,
    native_token_symbol: "ETH",
    explorer_slug: "optimism"
  },
  %{
    chain_id: 8453,
    name: "Base",
    chain_type: :optimistic_rollup,
    native_token_symbol: "ETH",
    explorer_slug: "base"
  },
  %{
    chain_id: 56,
    name: "BNB Smart Chain",
    chain_type: :sidechain,
    native_token_symbol: "BNB",
    explorer_slug: "bnb"
  },
  %{
    chain_id: 137,
    name: "Polygon",
    chain_type: :sidechain,
    native_token_symbol: "POL",
    explorer_slug: "polygon"
  }
]

for attrs <- chains do
  case Repo.get(Chain, attrs.chain_id) do
    nil ->
      %Chain{}
      |> Chain.changeset(attrs)
      |> Repo.insert!()
      IO.puts("Seeded chain: #{attrs.name} (#{attrs.chain_id})")

    _existing ->
      IO.puts("Chain already exists: #{attrs.name} (#{attrs.chain_id})")
  end
end

# Seed common tokens
alias Rexplorer.Schema.{Token, TokenAddress}

tokens = [
  %{
    name: "USD Coin",
    symbol: "USDC",
    decimals: 6,
    addresses: %{
      1 => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      10 => "0x0b2c639c533813f4aa9d7837caf62653d097ff85",
      8453 => "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
      56 => "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
      137 => "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"
    }
  },
  %{
    name: "Tether USD",
    symbol: "USDT",
    decimals: 6,
    addresses: %{
      1 => "0xdac17f958d2ee523a2206206994597c13d831ec7",
      10 => "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58",
      137 => "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
    }
  },
  %{
    name: "Binance-Peg BSC-USD",
    symbol: "USDT",
    decimals: 18,
    addresses: %{
      56 => "0x55d398326f99059ff775485246999027b3197955"
    }
  },
  %{
    name: "Dai Stablecoin",
    symbol: "DAI",
    decimals: 18,
    addresses: %{
      1 => "0x6b175474e89094c44da98b954eedeac495271d0f",
      10 => "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1",
      137 => "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063"
    }
  },
  %{
    name: "Wrapped Ether",
    symbol: "WETH",
    decimals: 18,
    addresses: %{
      1 => "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
      10 => "0x4200000000000000000000000000000000000006",
      8453 => "0x4200000000000000000000000000000000000006",
      137 => "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619"
    }
  }
]

for token_attrs <- tokens do
  token =
    case Repo.get_by(Token, name: token_attrs.name) do
      nil ->
        %Token{}
        |> Token.changeset(Map.take(token_attrs, [:name, :symbol, :decimals]))
        |> Repo.insert!()

      existing ->
        existing
    end

  for {chain_id, contract_address} <- token_attrs.addresses do
    case Repo.get_by(TokenAddress, chain_id: chain_id, contract_address: contract_address) do
      nil ->
        %TokenAddress{}
        |> TokenAddress.changeset(%{
          token_id: token.id,
          chain_id: chain_id,
          contract_address: contract_address
        })
        |> Repo.insert!()

      _ ->
        :ok
    end
  end

  IO.puts("Seeded token: #{token_attrs.symbol}")
end
