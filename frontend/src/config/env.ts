// Environment configuration
export const config = {
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8080',
  frontendUrl: import.meta.env.VITE_FRONTEND_URL || 'http://localhost:5173',
  adminSubdomain: import.meta.env.VITE_ADMIN_SUBDOMAIN || 'admin',
} as const

// Helper to build tenant URL
export function getTenantUrl(subdomain: string): string {
  const url = new URL(config.frontendUrl)
  url.hostname = `${subdomain}.${url.hostname}`
  return url.toString().replace(/\/$/, '') // Remove trailing slash
}

// Helper to build API endpoint
export function getApiEndpoint(path: string): string {
  return `${config.apiUrl}${path.startsWith('/') ? path : '/' + path}`
}
