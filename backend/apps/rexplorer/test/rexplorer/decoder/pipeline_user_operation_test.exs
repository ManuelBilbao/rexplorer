defmodule Rexplorer.Decoder.PipelineUserOperationTest do
  use ExUnit.Case, async: true

  alias Rexplorer.Decoder.Pipeline

  @smart_account "0xa1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1"
  @paymaster "0x9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e"
  @factory "0xfafafafafafafafafafafafafafafafafafafafa"
  @recipient "0x0101010101010101010101010101010101010101"
  @token "0x7777777777777777777777777777777777777777"

  defp operation(op_extra, opts \\ []) do
    %{
      operation_type: :user_operation,
      from_address: @smart_account,
      to_address: Keyword.get(opts, :to, @token),
      value: Decimal.new(0),
      input: Keyword.get(opts, :input, transfer_calldata()),
      chain_id: 1,
      op_extra: op_extra
    }
  end

  defp transfer_calldata do
    ABI.encode("transfer(address,uint256)", [
      Base.decode16!("0101010101010101010101010101010101010101", case: :lower),
      5
    ])
  end

  describe "user_operation narration" do
    test "names the smart account as the actor" do
      {:ok, summary} = Pipeline.decode_operation(operation(%{}), %{})

      assert String.starts_with?(summary, "Smart account #{@smart_account} transferred")
      assert summary =~ @recipient
    end

    test "adds a sponsorship clause when a paymaster paid" do
      {:ok, summary} = Pipeline.decode_operation(operation(%{"paymaster" => @paymaster}), %{})

      assert String.ends_with?(summary, "(gas paid by paymaster #{@paymaster})")
    end

    test "omits the sponsorship clause when self-funded" do
      {:ok, summary} = Pipeline.decode_operation(operation(%{}), %{})

      refute summary =~ "paymaster"
    end

    test "says when the operation deployed its account" do
      {:ok, summary} = Pipeline.decode_operation(operation(%{"factory" => @factory}), %{})

      assert summary =~ "account deployed by #{@factory}"
    end

    test "combines deployment and sponsorship into one clause" do
      {:ok, summary} =
        Pipeline.decode_operation(
          operation(%{"factory" => @factory, "paymaster" => @paymaster}),
          %{}
        )

      assert summary =~
               "(account deployed by #{@factory}, gas paid by paymaster #{@paymaster})"
    end

    test "marks a failed UserOperation" do
      {:ok, summary} =
        Pipeline.decode_operation(
          operation(%{"success" => false, "paymaster" => @paymaster}),
          %{}
        )

      assert String.starts_with?(summary, "Failed: Smart account")
      assert summary =~ "gas paid by paymaster"
    end

    test "does not mark a successful UserOperation" do
      {:ok, summary} = Pipeline.decode_operation(operation(%{"success" => true}), %{})

      refute String.starts_with?(summary, "Failed:")
    end

    test "keeps the AA framing when the inner call has no known selector" do
      unknown = <<0xDE, 0xAD, 0xBE, 0xEF>> <> :binary.copy(<<0>>, 32)

      {:ok, summary} =
        Pipeline.decode_operation(
          operation(%{"paymaster" => @paymaster}, input: unknown, to: @smart_account),
          %{}
        )

      assert String.starts_with?(summary, "Smart account #{@smart_account}: Called 0xdeadbeef")
      assert summary =~ "gas paid by paymaster"
    end

    test "leaves other operation types alone" do
      call = %{
        operation_type: :call,
        from_address: @smart_account,
        to_address: @token,
        value: Decimal.new(0),
        input: transfer_calldata(),
        chain_id: 1,
        op_extra: %{"paymaster" => @paymaster}
      }

      {:ok, summary} = Pipeline.decode_operation(call, %{})

      refute summary =~ "Smart account"
      refute summary =~ "paymaster"
    end
  end

  describe "decoder version" do
    test "is bumped so existing operations re-narrate" do
      assert Pipeline.decoder_version() >= 3
    end
  end
end
