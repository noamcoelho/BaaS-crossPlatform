import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // O SDK do Firebase sozinho passa de 500 kB minificado; para um painel interno é aceitável.
  build: { chunkSizeWarningLimit: 1000 },
})
