defmodule Rexplorer.Labels do
  @moduledoc """
  Derives role labels for addresses from the operations extracted for a block.

  A label describes an observed on-chain role, never a guess about ownership
  or identity. The roles are derived, not curated: they come from what the
  block actually contained, so they need no per-chain list to maintain.

  ## Roles

  | Role | Derived from |
  |------|--------------|
  | `ERC-4337 EntryPoint v0.6` / `v0.7` | the `entry_point` a bundle was submitted to |
  | `ERC-4337 Account Factory` | a UserOperation's `initCode` prefix |
  | `ERC-4337 Paymaster` | a UserOperation's sponsor |
  | `Smart Account` | the `sender` of a UserOperation |

  When one address turns up in two roles within a block — a paymaster that is
  itself a smart account, say — the more specific role wins, in the order
  above. The order is fixed so that indexing the same block twice produces the
  same label.

  Labels are written only where an address has none: see
  `Rexplorer.Addresses.upsert_discovered/1`.
  """

  # Highest priority first — the order that resolves an address holding two roles.
  @priority [:entry_point, :factory, :paymaster, :smart_account]

  @doc """
  Returns `%{address => label}` for the roles found in a block's operations.

  Takes operation attribute maps as produced by the unwrappers (the ERC-4337
  ones carry their roles in `op_extra`). Operations of other types contribute
  nothing.
  """
  @spec from_operations([map()]) :: %{String.t() => String.t()}
  def from_operations(operations) when is_list(operations) do
    operations
    |> Enum.flat_map(&roles_in/1)
    |> Enum.group_by(fn {address, _role} -> address end, fn {_address, role} -> role end)
    |> Map.new(fn {address, roles} -> {address, label_for(highest_priority(roles))} end)
  end

  def from_operations(_), do: %{}

  defp roles_in(%{operation_type: :user_operation} = operation) do
    extra = Map.get(operation, :op_extra) || %{}

    [
      {extra["entry_point"], {:entry_point, extra["entry_point_version"]}},
      {extra["factory"], :factory},
      {extra["paymaster"], :paymaster},
      {Map.get(operation, :from_address), :smart_account}
    ]
    |> Enum.reject(fn {address, _role} -> is_nil(address) end)
  end

  defp roles_in(_), do: []

  defp highest_priority(roles) do
    Enum.min_by(roles, fn role -> Enum.find_index(@priority, &(&1 == kind(role))) end)
  end

  defp kind({kind, _detail}), do: kind
  defp kind(kind), do: kind

  defp label_for({:entry_point, version}) when is_binary(version),
    do: "ERC-4337 EntryPoint v#{version}"

  defp label_for({:entry_point, _}), do: "ERC-4337 EntryPoint"
  defp label_for(:factory), do: "ERC-4337 Account Factory"
  defp label_for(:paymaster), do: "ERC-4337 Paymaster"
  defp label_for(:smart_account), do: "Smart Account"
end
