defmodule Rexplorer.AddressLabelsTest do
  use Rexplorer.DataCase, async: true

  alias Rexplorer.Addresses
  alias Rexplorer.Schema.{Address, Chain}

  @chain_id 99992

  setup do
    chain =
      case Repo.get(Chain, @chain_id) do
        nil ->
          %Chain{}
          |> Chain.changeset(%{
            chain_id: @chain_id,
            name: "Test Chain Labels",
            chain_type: :l1,
            native_token_symbol: "ETH",
            explorer_slug: "test-labels"
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    %{chain: chain}
  end

  defp entry(hash, label \\ nil) do
    base = %{
      chain_id: @chain_id,
      hash: hash,
      is_contract: false,
      first_seen_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    if label, do: Map.put(base, :label, label), else: base
  end

  defp label_of(hash), do: Repo.get_by!(Address, chain_id: @chain_id, hash: hash).label

  test "a labelled address is inserted with its label" do
    :ok = Addresses.upsert_discovered([entry("0xep1", "ERC-4337 EntryPoint v0.7")])

    assert label_of("0xep1") == "ERC-4337 EntryPoint v0.7"
  end

  test "an address seen earlier without a label gains one" do
    :ok = Addresses.upsert_discovered([entry("0xacc1")])
    assert label_of("0xacc1") == nil

    :ok = Addresses.upsert_discovered([entry("0xacc1", "Smart Account")])
    assert label_of("0xacc1") == "Smart Account"
  end

  test "an existing label is never overwritten" do
    :ok = Addresses.upsert_discovered([entry("0xboth", "ERC-4337 Paymaster")])
    :ok = Addresses.upsert_discovered([entry("0xboth", "Smart Account")])

    assert label_of("0xboth") == "ERC-4337 Paymaster"
  end

  test "re-indexing the same block leaves labels identical" do
    addresses = [
      entry("0xep2", "ERC-4337 EntryPoint v0.6"),
      entry("0xpm2", "ERC-4337 Paymaster"),
      entry("0xacc2", "Smart Account"),
      entry("0xeoa2")
    ]

    :ok = Addresses.upsert_discovered(addresses)
    first_pass = Enum.map(addresses, &label_of(&1.hash))

    :ok = Addresses.upsert_discovered(addresses)
    assert Enum.map(addresses, &label_of(&1.hash)) == first_pass

    assert first_pass == [
             "ERC-4337 EntryPoint v0.6",
             "ERC-4337 Paymaster",
             "Smart Account",
             nil
           ]
  end

  test "first_seen_at is not moved forward by a later sighting" do
    early = ~U[2020-01-01 00:00:00Z]

    :ok = Addresses.upsert_discovered([%{entry("0xold") | first_seen_at: early}])
    :ok = Addresses.upsert_discovered([entry("0xold", "Smart Account")])

    address = Repo.get_by!(Address, chain_id: @chain_id, hash: "0xold")

    assert DateTime.compare(address.first_seen_at, early) == :eq
    assert address.label == "Smart Account"
  end

  test "an empty list is a no-op" do
    assert Addresses.upsert_discovered([]) == :ok
  end
end
