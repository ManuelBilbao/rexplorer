import Badge from '../ui/Badge'

interface StatusBadgeProps {
  status: boolean | null
}

export function StatusBadge({ status }: StatusBadgeProps) {
  if (status === true) {
    return <Badge variant="green">Success</Badge>
  }

  if (status === false) {
    return <Badge variant="red">Failed</Badge>
  }

  return <Badge variant="gray">Pending</Badge>
}
