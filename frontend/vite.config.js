import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(({ mode }) => {

  return {

  plugins: [
    vue(),
    tailwindcss(),
  ],
  server: {
    allowedHosts: [
      env.DOMAIN_OR_IP
    ],
    watch: {
      usePolling: true,
    },
    host: true, // Needed for Docker mapping
    port: 5173,
  },
}
})