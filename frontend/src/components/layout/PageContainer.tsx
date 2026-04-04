import { Outlet } from 'react-router'
import { Header } from './Header'
import { Footer } from './Footer'

export function PageContainer() {
  return (
    <div className="min-h-screen flex flex-col bg-rex-bg dark:bg-rex-bg-dark">
      <Header />
      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-6">
        <Outlet />
      </main>
      <Footer />
    </div>
  )
}
