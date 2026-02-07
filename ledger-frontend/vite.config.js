import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {

  plugins: [
    vue()
  ],
  server: {
    allowedHosts: [
      env.DOMAIN_OR_IP
    ],
    watch: {
      usePolling: true,
    },
    host: true, // Needed for Docker mapping
    port: 5174,
  },
  base: '/accounting/',
}
})