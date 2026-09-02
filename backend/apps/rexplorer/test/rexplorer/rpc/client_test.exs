defmodule Rexplorer.RPC.ClientTest do
  use ExUnit.Case, async: true

  alias Rexplorer.RPC.Client

  describe "hex helpers" do
    test "hex_to_integer/1 decodes hex string" do
      assert Client.hex_to_integer("0x1") == 1
      assert Client.hex_to_integer("0xff") == 255
      assert Client.hex_to_integer("0x1312D00") == 20_000_000
    end

    test "hex_to_integer/1 handles nil" do
      assert Client.hex_to_integer(nil) == nil
    end

    test "integer_to_hex/1 encodes integer" do
      assert Client.integer_to_hex(1) == "0x1"
      assert Client.integer_to_hex(255) == "0xFF"
      assert Client.integer_to_hex(20_000_000) == "0x1312D00"
    end

    test "hex_to_binary/1 decodes hex to bytes" do
      assert Client.hex_to_binary("0xDEADBEEF") == <<0xDE, 0xAD, 0xBE, 0xEF>>
    end

    test "hex_to_binary/1 handles nil and empty" do
      assert Client.hex_to_binary(nil) == nil
      assert Client.hex_to_binary("") == <<>>
    end
  end

  describe "call/3 with mock server" do
    test "returns result on successful RPC response" do
      url = start_mock_rpc(fn _body ->
        %{"jsonrpc" => "2.0", "id" => 1, "result" => "0x1312D00"}
      end)

      assert {:ok, "0x1312D00"} = Client.call(url, "eth_blockNumber")
    end

    test "returns error on JSON-RPC error response" do
      url = start_mock_rpc(fn _body ->
        %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32601, "message" => "Method not found"}}
      end)

      assert {:error, %{code: -32601, message: "Method not found"}} =
               Client.call(url, "eth_nonExistent")
    end

    test "returns error on network failure" do
      assert {:error, _reason} = Client.call("http://localhost:1", "eth_blockNumber")
    end
  end

  describe "get_latest_block_number/1" do
    test "returns decoded integer" do
      url = start_mock_rpc(fn _body ->
        %{"jsonrpc" => "2.0", "id" => 1, "result" => "0x1312D00"}
      end)

      assert {:ok, 20_000_000} = Client.get_latest_block_number(url)
    end
  end

  describe "get_block/2" do
    test "returns nil for non-existent block" do
      url = start_mock_rpc(fn _body ->
        %{"jsonrpc" => "2.0", "id" => 1, "result" => nil}
      end)

      assert {:ok, nil} = Client.get_block(url, 999_999_999)
    end

    test "sends correct params" do
      url = start_mock_rpc(fn body ->
        decoded = Jason.decode!(body)
        assert decoded["method"] == "eth_getBlockByNumber"
        assert decoded["params"] == ["0xF4240", true]
        %{"jsonrpc" => "2.0", "id" => 1, "result" => %{"number" => "0xF4240"}}
      end)

      assert {:ok, %{"number" => "0xF4240"}} = Client.get_block(url, 1_000_000)
    end
  end

  describe "get_block_receipts/2" do
    test "returns list of receipts" do
      url = start_mock_rpc(fn _body ->
        %{"jsonrpc" => "2.0", "id" => 1, "result" => [%{"status" => "0x1", "gasUsed" => "0x5208"}]}
      end)

      assert {:ok, [%{"status" => "0x1"}]} = Client.get_block_receipts(url, 100)
    end
  end

  # Start a Bandit server that responds to JSON-RPC requests using an Agent for state
  defp start_mock_rpc(handler_fn) do
    {:ok, agent} = Agent.start_link(fn -> handler_fn end)

    {:ok, pid} =
      Bandit.start_link(
        plug: {Rexplorer.RPC.ClientTest.MockPlug, agent},
        port: 0,
        startup_log: false
      )

    {:ok, {_ip, port}} = ThousandIsland.listener_info(pid)

    on_exit(fn ->
      try do
        Supervisor.stop(pid, :normal, 100)
      catch
        :exit, _ -> :ok
      end

      try do
        Agent.stop(agent, :normal, 100)
      catch
        :exit, _ -> :ok
      end
    end)

    "http://localhost:#{port}"
  end

  defmodule MockPlug do
    @behaviour Plug

    @impl true
    def init(agent), do: agent

    @impl true
    def call(conn, agent) do
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      handler_fn = Agent.get(agent, & &1)
      response = handler_fn.(body)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(response))
    end
  end
end
