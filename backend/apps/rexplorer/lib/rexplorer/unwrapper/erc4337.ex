defmodule Rexplorer.Unwrapper.ERC4337 do
  @moduledoc """
  Unwraps ERC-4337 bundles into the user intents they carry.

  A bundler submits `handleOps` to an EntryPoint, so without unwrapping the
  whole bundle reads as one call from the bundler EOA — the one address in the
  transaction with no user intent at all. This unwrapper attributes each
  UserOperation to the smart account that authored it, points it at the real
  target of its inner call, and records the AA-specific facts in `op_extra`.

  ## Detection

  Selector-based, covering both live EntryPoint calldata shapes:

  | EntryPoint | Selector | Ops array element |
  |------------|----------|-------------------|
  | v0.6       | `0x1fad948c` | `UserOperation` (11 fields) |
  | v0.7/v0.8  | `0x765e827f` | `PackedUserOperation` (9 fields) |

  The two shapes differ only in how gas parameters are encoded. The fields this
  module reads sit at the same tuple positions in both: `sender` first,
  `initCode` third, `callData` fourth, and `paymasterAndData` second from last.

  v0.8 kept v0.7's packed calldata, so the selector alone cannot tell them
  apart. The recorded version therefore prefers the canonical EntryPoint
  addresses and falls back to the calldata shape for any other deployment.
  Detection stays selector-based: the address is consulted only to name a
  version, never to decide whether this is a bundle.

  ## Two-level unwrap

  A UserOperation's `callData` is a call to the smart account itself, so
  stopping at one level would narrate every AA transaction as "Called execute
  on 0x…". This module peels that second layer too:

  | Account calldata | Produces |
  |------------------|----------|
  | `execute(address,uint256,bytes)` | one operation at the inner target |
  | `executeBatch(address[],bytes[])` | one operation per inner call |
  | `executeBatch(address[],uint256[],bytes[])` | one operation per inner call, with values |
  | anything else | one operation at the smart account, raw `callData` kept |

  Operations from the same UserOperation share a `user_op_index`, so a batched
  UserOperation can be grouped back together for display.

  ## Event correlation

  The EntryPoint emits one `UserOperationEvent` per UserOperation, in bundle
  order, whether it succeeded or reverted. When the transaction's logs are
  present they are matched positionally and are authoritative — a v0.7
  paymaster address is otherwise buried in an opaque `paymasterAndData`.
  Correlation is applied only when the counts agree: attributing one user's
  hash and paymaster to another user's operation is worse than omitting both.

  ```mermaid
  graph TD
      TX["handleOps tx<br/>from: bundler EOA"] --> M{"selector?"}
      M -->|"0x1fad948c"| V06["decode UserOperation[]"]
      M -->|"0x765e827f"| V07["decode PackedUserOperation[]"]
      M -->|"other"| NM["no match"]

      V06 --> OPS["UserOps"]
      V07 --> OPS

      LOGS["logs"] --> EV["filter UserOperationEvent"]
      EV --> CNT{"count == ops?"}
      CNT -->|yes| ZIP["zip by position:<br/>hash, paymaster, success, gas"]
      CNT -->|no| CD["calldata only:<br/>paymasterAndData, initCode"]

      OPS --> PEEL["peel callData"]
      ZIP --> PEEL
      CD --> PEEL

      PEEL -->|execute| ONE["1 operation"]
      PEEL -->|executeBatch| MANY["N operations"]
      PEEL -->|unknown| RAW["1 operation at the account"]

      ONE --> OUT["user_operation ops<br/>+ op_extra"]
      MANY --> OUT
      RAW --> OUT
  ```
  """

  @behaviour Rexplorer.Unwrapper

  alias Rexplorer.Decoder.ABI, as: ABIRegistry
  alias Rexplorer.Decoder.EventDecoder

  # EntryPoint handleOps selectors
  @handle_ops_v06 <<0x1F, 0xAD, 0x94, 0x8C>>
  @handle_ops_v07 <<0x76, 0x5E, 0x82, 0x7F>>

  # Smart account execution selectors
  @execute <<0xB6, 0x1D, 0x27, 0xF6>>
  @execute_batch <<0x18, 0xDF, 0xB3, 0xC7>>
  @execute_batch_with_values <<0x47, 0xE1, 0xDA, 0x2A>>

  @user_operation_event "0x49628fd1471006c1482da88028e9ce4dbb080b815c9b0344d39e5a8e6ec1419f"

  # Canonical EntryPoint deployments, for naming a version the calldata shape
  # cannot distinguish. Unknown deployments fall back to the shape.
  @entry_point_versions %{
    "0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789" => "0.6",
    "0x0000000071727de22e5e9d8baf0edac6f37da032" => "0.7",
    "0x4337084d9e255ff0702461cf8895ce9e3b5ff108" => "0.8"
  }

  @zero_address "0x0000000000000000000000000000000000000000"

  @impl true
  def matches?(%{input: <<selector::binary-size(4), _rest::binary>>}, _chain_id) do
    selector in [@handle_ops_v06, @handle_ops_v07]
  end

  def matches?(_, _), do: false

  @impl true
  def unwrap(transaction, _chain_id) do
    with {:ok, shape_version} <- calldata_shape_version(transaction.input),
         {:ok, user_ops} <- decode_user_ops(transaction.input) do
      version = entry_point_version(transaction.to_address, shape_version)

      events = correlate_events(Map.get(transaction, :logs) || [], length(user_ops))

      user_ops
      |> Enum.with_index()
      |> Enum.flat_map(fn {user_op, index} ->
        operations_for(user_op, index, Enum.at(events, index), transaction, version)
      end)
      |> reindex()
    else
      _ -> []
    end
  rescue
    _ -> []
  end

  # ── Bundle decoding ──────────────────────────────────────────────────

  defp calldata_shape_version(<<@handle_ops_v06, _rest::binary>>), do: {:ok, "0.6"}
  defp calldata_shape_version(<<@handle_ops_v07, _rest::binary>>), do: {:ok, "0.7"}
  defp calldata_shape_version(_), do: :error

  defp entry_point_version(address, shape_version) when is_binary(address) do
    Map.get(@entry_point_versions, String.downcase(address), shape_version)
  end

  defp entry_point_version(_address, shape_version), do: shape_version

  defp decode_user_ops(input) do
    case ABIRegistry.decode(input) do
      {:ok, %{function: "handleOps", params: %{"ops" => ops}}} when is_list(ops) and ops != [] ->
        {:ok, ops}

      _ ->
        :error
    end
  end

  # Both shapes put sender first, initCode third and callData fourth, and
  # paymasterAndData second from last — 11 fields unpacked, 9 packed.
  defp user_op_fields(tuple) when is_tuple(tuple) and tuple_size(tuple) in [9, 11] do
    %{
      sender: normalize_address(elem(tuple, 0)),
      init_code: elem(tuple, 2),
      call_data: elem(tuple, 3),
      paymaster_and_data: elem(tuple, tuple_size(tuple) - 2)
    }
  end

  defp user_op_fields(_), do: nil

  # ── Event correlation ────────────────────────────────────────────────

  defp correlate_events(logs, op_count) do
    decoded =
      logs
      |> Enum.filter(&user_operation_event?/1)
      |> Enum.map(&decode_event/1)

    if length(decoded) == op_count and not Enum.any?(decoded, &is_nil/1) do
      decoded
    else
      # A mismatch means the bundle is not the shape we think it is. Zipping
      # positionally would misattribute one user's hash to another's operation.
      []
    end
  end

  defp user_operation_event?(%{topic0: topic0}) when is_binary(topic0) do
    String.downcase(topic0) == @user_operation_event
  end

  defp user_operation_event?(_), do: false

  defp decode_event(log) do
    case EventDecoder.decode_log(log) do
      %{event_name: "UserOperationEvent", params: params} ->
        %{
          user_op_hash: params["userOpHash"],
          paymaster: presence(params["paymaster"]),
          success: params["success"] == "true",
          actual_gas_cost: params["actualGasCost"]
        }

      _ ->
        nil
    end
  end

  # ── Operation construction ───────────────────────────────────────────

  defp operations_for(user_op, user_op_index, event, transaction, version) do
    case user_op_fields(user_op) do
      nil ->
        []

      fields ->
        extra = op_extra(fields, user_op_index, event, transaction, version)

        fields.call_data
        |> inner_calls(fields.sender)
        |> Enum.map(fn {to_address, value, input} ->
          %{
            operation_type: :user_operation,
            operation_index: 0,
            from_address: fields.sender,
            to_address: to_address,
            value: to_decimal(value),
            input: presence(input),
            op_extra: extra
          }
        end)
    end
  end

  defp op_extra(fields, user_op_index, event, transaction, version) do
    %{
      "user_op_index" => user_op_index,
      "entry_point" => transaction.to_address,
      "entry_point_version" => version
    }
    |> put_present("paymaster", paymaster(event, fields.paymaster_and_data))
    |> put_present("factory", address_prefix(fields.init_code))
    |> put_present("user_op_hash", event && event.user_op_hash)
    |> put_present("actual_gas_cost", event && event.actual_gas_cost)
    |> put_success(event)
  end

  # The event's paymaster is what the EntryPoint actually charged; the
  # calldata prefix is the fallback when logs are unavailable.
  defp paymaster(%{paymaster: paymaster}, _paymaster_and_data) when is_binary(paymaster) do
    if paymaster == @zero_address, do: nil, else: paymaster
  end

  defp paymaster(_event, paymaster_and_data), do: address_prefix(paymaster_and_data)

  defp address_prefix(<<address::binary-size(20), _rest::binary>>),
    do: normalize_address(address)

  defp address_prefix(_), do: nil

  defp put_success(extra, %{success: success}) when is_boolean(success),
    do: Map.put(extra, "success", success)

  defp put_success(extra, _), do: extra

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)

  # ── Account call peeling ─────────────────────────────────────────────

  defp inner_calls(<<@execute, _rest::binary>> = call_data, sender) do
    case ABIRegistry.decode(call_data) do
      {:ok, %{function: "execute", params: params}} ->
        [{normalize_address(params["dest"]), params["value"], params["func"]}]

      _ ->
        [{sender, 0, call_data}]
    end
  end

  defp inner_calls(<<@execute_batch, _rest::binary>> = call_data, sender) do
    case ABIRegistry.decode(call_data) do
      {:ok, %{function: "executeBatch", params: %{"dest" => dests, "func" => funcs}}}
      when is_list(dests) and is_list(funcs) and dests != [] ->
        Enum.zip_with(dests, funcs, fn dest, func -> {normalize_address(dest), 0, func} end)

      _ ->
        [{sender, 0, call_data}]
    end
  end

  defp inner_calls(<<@execute_batch_with_values, _rest::binary>> = call_data, sender) do
    case ABIRegistry.decode(call_data) do
      {:ok,
       %{function: "executeBatch", params: %{"dest" => dests, "value" => values, "func" => funcs}}}
      when is_list(dests) and is_list(values) and is_list(funcs) and dests != [] ->
        [dests, values, funcs]
        |> Enum.zip()
        |> Enum.map(fn {dest, value, func} -> {normalize_address(dest), value, func} end)

      _ ->
        [{sender, 0, call_data}]
    end
  end

  # An account interface we do not know: keep the operation at the account
  # with its calldata intact rather than losing it.
  defp inner_calls(call_data, sender), do: [{sender, 0, call_data}]

  defp reindex(operations) do
    operations
    |> Enum.with_index()
    |> Enum.map(fn {operation, index} -> %{operation | operation_index: index} end)
  end

  # ── Value helpers ────────────────────────────────────────────────────

  defp normalize_address(address) when is_binary(address) and byte_size(address) == 20 do
    "0x" <> Base.encode16(address, case: :lower)
  end

  defp normalize_address(address) when is_binary(address), do: String.downcase(address)
  defp normalize_address(_), do: nil

  defp presence(nil), do: nil
  defp presence(<<>>), do: nil
  defp presence(value), do: value

  defp to_decimal(%Decimal{} = value), do: value
  defp to_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp to_decimal(_), do: Decimal.new(0)
end
