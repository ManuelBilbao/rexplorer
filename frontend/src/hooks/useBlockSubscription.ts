import { useState, useEffect, useRef } from 'react'
import { useSocket } from './useSocket'
import type { Channel } from 'phoenix'

interface BlockEvent {
  block_number: number
  hash: string
  timestamp: string
  transaction_count: number
  gas_used: number
}

export function useBlockSubscription(chainSlug: string | null) {
  const socket = useSocket()
  const channelRef = useRef<Channel | null>(null)
  const [latestBlock, setLatestBlock] = useState<BlockEvent | null>(null)

  useEffect(() => {
    if (!socket || !chainSlug) return

    const channel = socket.channel(`blocks:${chainSlug}`, {})

    channel.on('new_block', (payload: BlockEvent) => {
      setLatestBlock(payload)
    })

    channel.join()
      .receive('ok', () => {})
      .receive('error', () => {})

    channelRef.current = channel

    return () => {
      channel.leave()
      channelRef.current = null
    }
  }, [socket, chainSlug])

  return latestBlock
}
