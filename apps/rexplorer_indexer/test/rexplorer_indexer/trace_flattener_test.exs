defmodule RexplorerIndexer.TraceFlattenerTest do
  use ExUnit.Case, async: true

  alias RexplorerIndexer.TraceFlattener

  describe "flatten_traces/1" do
    test "extracts addresses from simple call" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{
            "type" => "CALL",
            "from" => "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            "to" => "0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
            "value" => "0x100"
          }
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.member?(result, "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      assert MapSet.member?(result, "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
      assert MapSet.size(result) == 2
    end

    test "extracts addresses from nested calls" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{
            "type" => "CALL",
            "from" => "0xAA",
            "to" => "0xBB",
            "value" => "0x0",
            "calls" => [
              %{
                "type" => "CALL",
                "from" => "0xBB",
                "to" => "0xCC",
                "value" => "0x100",
                "calls" => [
                  %{
                    "type" => "CALL",
                    "from" => "0xCC",
                    "to" => "0xDD",
                    "value" => "0x50"
                  }
                ]
              }
            ]
          }
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.member?(result, "0xaa")
      assert MapSet.member?(result, "0xbb")
      assert MapSet.member?(result, "0xcc")
      assert MapSet.member?(result, "0xdd")
      assert MapSet.size(result) == 4
    end

    test "extracts CREATE addresses" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{
            "type" => "CREATE",
            "from" => "0xAA",
            "to" => "0xNEWCONTRACT",
            "value" => "0x0"
          }
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.member?(result, "0xaa")
      assert MapSet.member?(result, "0xnewcontract")
    end

    test "extracts SELFDESTRUCT addresses" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{
            "type" => "CALL",
            "from" => "0xAA",
            "to" => "0xBB",
            "value" => "0x0",
            "calls" => [
              %{
                "type" => "SELFDESTRUCT",
                "from" => "0xBB",
                "to" => "0xBENEFICIARY",
                "value" => "0xFFF"
              }
            ]
          }
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.member?(result, "0xbeneficiary")
      assert MapSet.member?(result, "0xbb")
    end

    test "handles empty traces" do
      assert TraceFlattener.flatten_traces([]) == MapSet.new()
    end

    test "handles nil input" do
      assert TraceFlattener.flatten_traces(nil) == MapSet.new()
    end

    test "deduplicates addresses across transactions" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{"type" => "CALL", "from" => "0xAA", "to" => "0xBB", "value" => "0x0"}
        },
        %{
          "txHash" => "0xtx2",
          "result" => %{"type" => "CALL", "from" => "0xBB", "to" => "0xCC", "value" => "0x0"}
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      # 0xBB appears in both but should be deduplicated
      assert MapSet.size(result) == 3
    end

    test "handles Ethrex format where result is an array of frames" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => [
            %{
              "type" => "CALL",
              "from" => "0x000000000000000000000000000000000000ffff",
              "to" => "0x000000000000000000000000000000000000ffff",
              "value" => "0x100",
              "calls" => [
                %{
                  "type" => "DELEGATECALL",
                  "from" => "0x000000000000000000000000000000000000ffff",
                  "to" => "0x000000000000000000000000000000000000efff",
                  "value" => "0x100",
                  "calls" => [
                    %{
                      "type" => "CALL",
                      "from" => "0x000000000000000000000000000000000000ffff",
                      "to" => "0x000cdf8dba2393a40857cbcb0fcd9b998a941078",
                      "value" => "0x100"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.member?(result, "0x000cdf8dba2393a40857cbcb0fcd9b998a941078")
      assert MapSet.member?(result, "0x000000000000000000000000000000000000ffff")
      assert MapSet.member?(result, "0x000000000000000000000000000000000000efff")
    end

    test "skips nil from/to values" do
      traces = [
        %{
          "txHash" => "0xtx1",
          "result" => %{"type" => "CREATE", "from" => "0xAA", "to" => nil, "value" => "0x0"}
        }
      ]

      result = TraceFlattener.flatten_traces(traces)

      assert MapSet.size(result) == 1
      assert MapSet.member?(result, "0xaa")
    end
  end
end
