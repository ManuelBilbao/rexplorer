import { useRef, useEffect } from 'react'
import { Socket } from 'phoenix'

let globalSocket: Socket | null = null

export function useSocket() {
  const socketRef = useRef<Socket | null>(null)

  useEffect(() => {
    if (!globalSocket) {
      globalSocket = new Socket('/socket', {})
      globalSocket.connect()
    }
    socketRef.current = globalSocket

    return () => {
      // Don't disconnect — socket is global singleton
    }
  }, [])

  return socketRef.current
}
