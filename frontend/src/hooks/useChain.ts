import { useParams } from 'react-router'

export function useChain() {
  const { chain } = useParams<{ chain: string }>()
  return chain ?? null
}
