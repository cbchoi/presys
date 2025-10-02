import { defineConfig } from 'vite'

export default defineConfig({
  root: 'slides',
  server: {
    port: 5173,
    host: '0.0.0.0',
    strictPort: false,
    fs: {
      allow: ['..']
    }
  },
  build: {
    outDir: '../dist',
    assetsDir: 'assets'
  }
})
