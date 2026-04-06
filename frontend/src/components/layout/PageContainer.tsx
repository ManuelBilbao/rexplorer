import { Outlet } from 'react-router'
import { Header } from './Header'
import { Footer } from './Footer'
import { Breadcrumb } from './Breadcrumb'

export function PageContainer() {
  return (
    <div className="min-h-screen flex flex-col bg-rex-bg">
      <Header />
      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-6">
        <Breadcrumb />
        <Outlet />
      </main>
      <Footer />
    </div>
  )
}
