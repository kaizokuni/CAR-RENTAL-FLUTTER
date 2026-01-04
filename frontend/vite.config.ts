import path from 'path'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@images': path.resolve(__dirname, './src/assets/images'),
      '@styles': path.resolve(__dirname, './src/assets/styles'),
      '@validators': path.resolve(__dirname, './src/@core/utils/validators'),
      '@views': path.resolve(__dirname, './src/views'),
      '@components': path.resolve(__dirname, './src/components'),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      '/uploads': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      }
    }
  }
})
