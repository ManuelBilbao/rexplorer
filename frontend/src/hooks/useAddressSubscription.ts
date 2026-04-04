import { useEffect, useRef } from 'react'
import { useSocket } from './useSocket'
import type { Channel } from 'phoenix'

export function useAddressSubscription(
  chainSlug: string | null,
  addressHash: string | undefined,
  onNewTransaction?: () => void
) {
  const socket = useSocket()
  const channelRef = useRef<Channel | null>(null)

  useEffect(() => {
    if (!socket || !chainSlug || !addressHash) return

    const channel = socket.channel(`address:${chainSlug}:${addressHash}`, {})

    channel.on('new_transaction', () => {
      onNewTransaction?.()
    })

    channel.on('new_token_transfer', () => {
      onNewTransaction?.()
    })

    channel.join()
      .receive('ok', () => {})
      .receive('error', () => {})

    channelRef.current = channel

    return () => {
      channel.leave()
      channelRef.current = null
    }
  }, [socket, chainSlug, addressHash, onNewTransaction])
}
