import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
  ],
  server: {
    allowedHosts: [
      'preciousplaceanu.duckdns.org'
    ],
    watch: {
      usePolling: true,
    },
    host: true, // Needed for Docker mapping
    port: 5173,
  },
})