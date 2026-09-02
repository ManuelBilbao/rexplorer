declare module 'phoenix' {
  export class Socket {
    constructor(endPoint: string, opts?: Record<string, unknown>)
    connect(): void
    disconnect(): void
    channel(topic: string, params?: Record<string, unknown>): Channel
  }

  export class Channel {
    join(): Push
    leave(): Push
    on<T = unknown>(event: string, callback: (payload: T) => void): number
    off(event: string, ref?: number): void
    push(event: string, payload?: Record<string, unknown>): Push
  }

  export class Push {
    receive<T = unknown>(status: string, callback: (response?: T) => void): Push
  }
}
