import { Link } from 'react-router'
import { SearchBar } from '../explorer/SearchBar'
import { useDarkMode } from '../../hooks/useDarkMode'

export function Header() {
  const { isDark, toggle } = useDarkMode()

  return (
    <header className="border-b border-rex-border dark:border-rex-border-dark bg-rex-bg dark:bg-rex-bg-dark sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 h-16 flex items-center gap-4">
        <Link to="/" className="text-xl font-bold text-rex-primary shrink-0">
          rexplorer
        </Link>

        <div className="flex-1 max-w-xl">
          <SearchBar />
        </div>

        <button
          onClick={toggle}
          className="p-2 rounded-lg hover:bg-rex-bg-tertiary dark:hover:bg-rex-bg-tertiary-dark transition-colors"
          aria-label="Toggle dark mode"
        >
          {isDark ? '\u2600\uFE0F' : '\uD83C\uDF19'}
        </button>
      </div>
    </header>
  )
}
