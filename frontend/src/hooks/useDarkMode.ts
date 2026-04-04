import { useState, useEffect } from 'react'

function getInitialMode(): boolean {
  const stored = localStorage.getItem('rexplorer-dark-mode')
  if (stored !== null) return stored === 'true'
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

export function useDarkMode() {
  const [isDark, setIsDark] = useState(getInitialMode)

  useEffect(() => {
    const root = document.documentElement
    if (isDark) {
      root.classList.add('dark')
    } else {
      root.classList.remove('dark')
    }
    localStorage.setItem('rexplorer-dark-mode', String(isDark))
  }, [isDark])

  return {
    isDark,
    toggle: () => setIsDark(prev => !prev),
  }
}
