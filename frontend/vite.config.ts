import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      '/api': 'http://localhost:4000',
      '/internal': 'http://localhost:4000',
      '/socket': {
        target: 'http://localhost:4000',
        ws: true,
      },
    },
  },
})
