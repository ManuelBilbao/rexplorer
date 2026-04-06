import { useState } from 'react'
import { useNavigate } from 'react-router'
import { useSearch } from '../../api/queries'

export function SearchBar() {
  const [query, setQuery] = useState('')
  const navigate = useNavigate()
  const { data, isLoading } = useSearch(query)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!data || data.type === 'unknown') return

    const result = data.results[0]
    if (!result) return

    switch (data.type) {
      case 'transaction':
        navigate(`/${result.chain}/tx/${result.hash}`)
        break
      case 'address':
        navigate(`/${result.chain}/address/${result.hash}`)
        break
      case 'block_number':
        navigate(`/${result.chain}/block/${result.block_number}`)
        break
    }

    setQuery('')
  }

  return (
    <form onSubmit={handleSubmit} className="w-full max-w-xl">
      <div className="relative">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search by address, tx hash, or block number..."
          className="w-full rounded-lg border border-rex-border bg-rex-bg-tertiary px-4 py-2 pr-10 text-sm text-rex-text placeholder-rex-text-secondary focus:border-rex-primary focus:outline-none focus:ring-1 focus:ring-rex-primary"
        />
        <button
          type="submit"
          disabled={isLoading || !data || data.type === 'unknown'}
          className="absolute right-2 top-1/2 -translate-y-1/2 text-rex-text-secondary hover:text-rex-text disabled:opacity-50"
        >
          <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
      </div>
    </form>
  )
}
