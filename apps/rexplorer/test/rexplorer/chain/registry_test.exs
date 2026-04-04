defmodule Rexplorer.Chain.RegistryTest do
  use ExUnit.Case, async: false

  alias Rexplorer.Chain.Registry

  describe "get_adapter/1" do
    test "returns adapter for known chain ID" do
      assert {:ok, Rexplorer.Chain.Ethereum} = Registry.get_adapter(1)
    end

    test "returns error for unknown chain ID" do
      assert {:error, :unknown_chain} = Registry.get_adapter(999_999)
    end
  end

  describe "list_adapters/0" do
    test "returns all registered adapters" do
      adapters = Registry.list_adapters()
      assert Rexplorer.Chain.Ethereum in adapters
    end
  end
end

defmodule Rexplorer.Chain.RegistryDbTest do
  use Rexplorer.DataCase, async: false

  alias Rexplorer.Chain.Registry

  describe "enabled_adapters/0" do
    test "returns adapters for enabled chains" do
      Repo.insert!(%Rexplorer.Schema.Chain{
        chain_id: 1,
        name: "Ethereum",
        chain_type: :l1,
        native_token_symbol: "ETH",
        explorer_slug: "ethereum",
        enabled: true
      })

      adapters = Registry.enabled_adapters()
      assert Rexplorer.Chain.Ethereum in adapters
    end

    test "excludes adapters for disabled chains" do
      Repo.insert!(%Rexplorer.Schema.Chain{
        chain_id: 1,
        name: "Ethereum",
        chain_type: :l1,
        native_token_symbol: "ETH",
        explorer_slug: "ethereum",
        enabled: false
      })

      adapters = Registry.enabled_adapters()
      refute Rexplorer.Chain.Ethereum in adapters
    end
  end
end
