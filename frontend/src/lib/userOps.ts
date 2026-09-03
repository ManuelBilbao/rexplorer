import type { Operation } from '../api/types'

/**
 * Groups a transaction's operations into UserOperations, in bundle order.
 * Operations that are not `user_operation` are ignored.
 */
export function groupUserOps(operations: Operation[]): Operation[][] {
  const groups = new Map<number, Operation[]>()

  for (const operation of operations) {
    if (operation.operation_type !== 'user_operation') continue

    const index = operation.op_extra?.user_op_index ?? 0
    const group = groups.get(index)
    if (group) {
      group.push(operation)
    } else {
      groups.set(index, [operation])
    }
  }

  return [...groups.entries()].sort(([a], [b]) => a - b).map(([, group]) => group)
}
