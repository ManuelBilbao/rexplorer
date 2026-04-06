interface StatusBadgeProps {
  status: boolean | null
}

export function StatusBadge({ status }: StatusBadgeProps) {
  if (status === true) {
    return (
      <span className="inline-flex items-center rounded-full bg-rex-success/10 px-2.5 py-0.5 text-xs font-medium text-rex-success">
        Success
      </span>
    )
  }

  if (status === false) {
    return (
      <span className="inline-flex items-center rounded-full bg-rex-danger/10 px-2.5 py-0.5 text-xs font-medium text-rex-danger">
        Failed
      </span>
    )
  }

  return (
    <span className="inline-flex items-center rounded-full bg-rex-bg-tertiary px-2.5 py-0.5 text-xs font-medium text-rex-text-secondary">
      Pending
    </span>
  )
}
