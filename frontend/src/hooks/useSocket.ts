import { useState } from 'react'
import { Socket } from 'phoenix'

let globalSocket: Socket | null = null

function getSocket(): Socket {
  if (!globalSocket) {
    globalSocket = new Socket('/socket', {})
    globalSocket.connect()
  }
  return globalSocket
}

export function useSocket(): Socket {
  // The socket is an app-wide singleton, not component state, so it is built
  // in a lazy initialiser rather than an effect. Returning it on the very
  // first render is what matters: the previous version stored it in a ref and
  // returned `null` initially, and because mutating a ref does not re-render,
  // subscribers kept that `null` and only ever connected if some unrelated
  // state change happened to re-render them.
  const [socket] = useState(getSocket)
  return socket
}
