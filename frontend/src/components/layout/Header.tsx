import { Link } from 'react-router'
import { SearchBar } from '../explorer/SearchBar'
import { useDarkMode } from '../../hooks/useDarkMode'

export function Header() {
  const { isDark, toggle } = useDarkMode()

  return (
    <header className="border-b border-rex-border bg-rex-bg-secondary sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 h-14 flex items-center gap-4">
        <Link to="/" className="text-lg font-bold text-rex-primary shrink-0 flex items-center gap-1.5">
          <span className="text-xl">🦕</span>
          <span>rexplorer</span>
        </Link>

        <div className="flex-1 max-w-lg">
          <SearchBar />
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={toggle}
            className="p-2 rounded-lg hover:bg-rex-bg-tertiary dark:hover:bg-rex-bg-tertiary-dark transition-colors text-sm"
            aria-label="Toggle dark mode"
          >
            {isDark ? '☀️' : '🌙'}
          </button>
        </div>
      </div>
    </header>
  )
}
