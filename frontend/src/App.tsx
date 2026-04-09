import { BrowserRouter, Routes, Route } from 'react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { PageContainer } from './components/layout/PageContainer'
import { LandingPage } from './pages/LandingPage'
import { HomePage } from './pages/HomePage'
import { BlockListPage } from './pages/BlockListPage'
import { BlockDetailPage } from './pages/BlockDetailPage'
import { TxDetailPage } from './pages/TxDetailPage'
import { AddressPage } from './pages/AddressPage'
import { NotFoundPage } from './pages/NotFoundPage'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 10_000,
      retry: 1,
    },
  },
})

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<PageContainer />}>
            <Route path="/" element={<LandingPage />} />
            <Route path="/:chain" element={<HomePage />} />
            <Route path="/:chain/blocks" element={<BlockListPage />} />
            <Route path="/:chain/block/:number" element={<BlockDetailPage />} />
            <Route path="/:chain/tx/:hash" element={<TxDetailPage />} />
            <Route path="/:chain/address/:hash" element={<AddressPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
