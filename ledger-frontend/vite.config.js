import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    vue(),
  ],
  server: {
    allowedHosts: [
      'preciousplaceanu.duckdns.org'
    ],
    watch: {
      usePolling: true,
    },
    host: true, // Needed for Docker mapping
    port: 5174,
  },
  base: '/accounting/',
})