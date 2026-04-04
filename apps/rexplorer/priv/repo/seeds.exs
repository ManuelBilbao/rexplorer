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
