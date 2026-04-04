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
          className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 pr-10 text-sm text-gray-900 placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder-gray-500 dark:focus:border-blue-400 dark:focus:ring-blue-400"
        />
        <button
          type="submit"
          disabled={isLoading || !data || data.type === 'unknown'}
          className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 disabled:opacity-50 dark:hover:text-gray-300"
        >
          <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
      </div>
    </form>
  )
}
