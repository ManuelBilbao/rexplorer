defmodule RexplorerIndexer.TraceFlattenerEntriesTest do
  use ExUnit.Case, async: true

  alias RexplorerIndexer.TraceFlattener

  describe "flatten_to_entries/1" do
    test "extracts value-transferring calls" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CALL",
              "from" => "0xAA",
              "to" => "0xBB",
              "value" => "0x100",
              "input" => "0xabcdef01",
              "calls" => []
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      assert length(entries) == 1

      [entry] = entries
      assert entry.from_address == "0xaa"
      assert entry.to_address == "0xbb"
      assert Decimal.equal?(entry.value, Decimal.new(256))
      assert entry.call_type == "call"
      assert entry.transaction_hash == "0xtx1"
      assert entry.trace_address == []
    end

    test "filters out zero-value calls" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CALL",
              "from" => "0xAA",
              "to" => "0xBB",
              "value" => "0x0",
              "input" => "0x",
              "calls" => [
                %{
                  "type" => "CALL",
                  "from" => "0xBB",
                  "to" => "0xCC",
                  "value" => "0x100",
                  "input" => "0x"
                }
              ]
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      # Only the inner call with value > 0
      assert length(entries) == 1
      assert hd(entries).from_address == "0xbb"
      assert hd(entries).to_address == "0xcc"
    end

    test "includes CREATE even with zero value" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CREATE",
              "from" => "0xAA",
              "to" => "0xNEW",
              "value" => "0x0",
              "input" => "0x60806040"
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      assert length(entries) == 1
      assert hd(entries).call_type == "create"
    end

    test "includes SELFDESTRUCT" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "SELFDESTRUCT",
              "from" => "0xDEAD",
              "to" => "0xBENEFICIARY",
              "value" => "0xFFF"
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      assert length(entries) == 1
      assert hd(entries).call_type == "selfdestruct"
    end

    test "assigns correct trace_address paths" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CALL",
              "from" => "0xA",
              "to" => "0xB",
              "value" => "0x1",
              "calls" => [
                %{
                  "type" => "CALL",
                  "from" => "0xB",
                  "to" => "0xC",
                  "value" => "0x1",
                  "calls" => [
                    %{
                      "type" => "CALL",
                      "from" => "0xC",
                      "to" => "0xD",
                      "value" => "0x1"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      assert length(entries) == 3

      paths = Enum.map(entries, & &1.trace_address)
      assert [] in paths
      assert [0] in paths
      assert [0, 0] in paths
    end

    test "extracts 4-byte input prefix" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CALL",
              "from" => "0xA",
              "to" => "0xB",
              "value" => "0x1",
              "input" => "0xb0f4d395000000000000000000000000000cdf8dba2393a40857cbcb0fcd9b998a941078"
            }
          ]
        }
      ]

      entries = TraceFlattener.flatten_to_entries(traces)
      [entry] = entries
      assert entry.input_prefix == <<0xB0, 0xF4, 0xD3, 0x95>>
    end

    test "handles empty traces" do
      assert TraceFlattener.flatten_to_entries([]) == []
    end

    test "handles nil input" do
      assert TraceFlattener.flatten_to_entries(nil) == []
    end
  end
end
