import { useState, useEffect } from 'react'
import { timeAgo, formatTimestamp } from '../../lib/format'

interface TimeAgoProps {
  timestamp: string
}

export function TimeAgo({ timestamp }: TimeAgoProps) {
  const [display, setDisplay] = useState(() => timeAgo(timestamp))

  useEffect(() => {
    const interval = setInterval(() => {
      setDisplay(timeAgo(timestamp))
    }, 30_000)
    return () => clearInterval(interval)
  }, [timestamp])

  return (
    <span
      className="text-rex-text-secondary"
      title={formatTimestamp(timestamp)}
    >
      {display}
    </span>
  )
}
