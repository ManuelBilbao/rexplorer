defmodule Rexplorer.Chain.EthrexTest do
  use ExUnit.Case, async: true

  alias Rexplorer.Chain.Ethrex

  @test_config [
    chain_id: 99999,
    name: "Test Ethrex",
    rpc_url: "http://localhost:1729",
    poll_interval_ms: 2_500,
    bridge_address: "0x000000000000000000000000000000000000ffff"
  ]

  setup_all do
    mod = Ethrex.create_adapter(@test_config)
    %{adapter: mod}
  end

  test "dynamic module is created", %{adapter: adapter} do
    assert adapter == :"Elixir.Rexplorer.Chain.Ethrex_99999"
    assert Code.ensure_loaded?(adapter)
  end

  test "chain_id from config", %{adapter: adapter} do
    assert adapter.chain_id() == 99999
  end

  test "chain_type is zk_rollup", %{adapter: adapter} do
    assert adapter.chain_type() == :zk_rollup
  end

  test "native_token is ETH", %{adapter: adapter} do
    assert adapter.native_token() == {"ETH", 18}
  end

  test "poll_interval_ms from config", %{adapter: adapter} do
    assert adapter.poll_interval_ms() == 2_500
  end

  test "bridge_contracts from config", %{adapter: adapter} do
    assert adapter.bridge_contracts() == ["0x000000000000000000000000000000000000ffff"]
  end

  test "block_fields includes batch_number", %{adapter: adapter} do
    fields = adapter.block_fields()
    assert {:batch_number, :integer} in fields
  end

  test "transaction_fields includes ethrex-specific fields", %{adapter: adapter} do
    fields = adapter.transaction_fields()
    assert {:is_privileged, :boolean} in fields
    assert {:l1_origin_hash, :string} in fields
    assert {:fee_token, :string} in fields
  end

  test "extract_operations delegates to unwrapper", %{adapter: adapter} do
    tx = %{
      from_address: "0xaaaa",
      to_address: "0xbbbb",
      value: Decimal.new(0),
      input: <<0x12, 0x34, 0x56, 0x78>>
    }

    assert [%{operation_type: :call}] = adapter.extract_operations(tx)
  end

  test "extract_token_transfers handles native transfer", %{adapter: adapter} do
    tx = %{
      from_address: "0xaaaa",
      to_address: "0xbbbb",
      value: Decimal.new("1000000000000000000"),
      logs: []
    }

    assert [%{token_type: :native}] = adapter.extract_token_transfers(tx)
  end

  test "multiple Ethrex chains can coexist" do
    config_a = [chain_id: 88881, name: "Ethrex A", rpc_url: "http://a", poll_interval_ms: 2000, bridge_address: "0xa"]
    config_b = [chain_id: 88882, name: "Ethrex B", rpc_url: "http://b", poll_interval_ms: 3000, bridge_address: "0xb"]

    mod_a = Ethrex.create_adapter(config_a)
    mod_b = Ethrex.create_adapter(config_b)

    assert mod_a.chain_id() == 88881
    assert mod_b.chain_id() == 88882
    assert mod_a.poll_interval_ms() == 2000
    assert mod_b.poll_interval_ms() == 3000
  end
end
