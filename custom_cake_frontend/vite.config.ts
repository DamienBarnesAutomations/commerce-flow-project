import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  
  return {
    plugins: [vue()],
    server: {
      host: true, 
      port: 5175,
      strictPort: true, // Forces 5175 or fails (better for debugging Docker)
      allowedHosts: [
        env.DOMAIN_OR_IP,
        '.localhost' // Allows local testing
      ],
      watch: {
        usePolling: true,
      },
    },
    base: '/custom-cake-manager/' 
  }
})