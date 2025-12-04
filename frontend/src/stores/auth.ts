import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { jwtDecode } from 'jwt-decode'

interface DecodedToken {
  sub: string
  tenant_id: string
  role: string
  exp: number
}

export const useAuthStore = defineStore('auth', () => {
  const router = useRouter()
  const token = ref<string | null>(localStorage.getItem('token'))
  const user = ref<any | null>(null)
  const role = ref<string | null>(null)
  const subscriptionTier = ref<string>('normal') // Default to normal
  const isAuthenticated = computed(() => !!token.value)
  const isSuperAdmin = computed(() => role.value === 'super_admin')
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Decode token on init to extract role
  if (token.value) {
    try {
      const decoded = jwtDecode<DecodedToken>(token.value)
      role.value = decoded.role
    } catch (e) {
      console.error('Failed to decode token', e)
    }
  }

  // Fetch user on init if token exists
  if (token.value) {
    fetchUser()
  }

  // API Base URL - use localhost for backend
  // The backend is always accessible at localhost:8080 regardless of frontend subdomain
  const API_URL = `http://localhost:8080/api/v1/auth`

  async function login(credentials: any) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-ID': 'default-tenant-id' 
        },
        body: JSON.stringify(credentials),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Login failed')
      }

      const data = await response.json()
      token.value = data.token
      localStorage.setItem('token', data.token)
      
      // Decode token to extract role
      try {
        const decoded = jwtDecode<DecodedToken>(data.token)
        role.value = decoded.role
      } catch (e) {
        console.error('Failed to decode token', e)
      }
      
      // Fetch user details
      await fetchUser()

      // Redirect based on role
      if (role.value === 'super_admin') {
        router.push('/dashboard/admin/dashboard')
      } else {
        router.push('/dashboard')
      }
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function register(userData: any) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-ID': 'default-tenant-id'
        },
        body: JSON.stringify(userData),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Registration failed')
      }

      router.push('/login')
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function fetchUser() {
    if (!token.value) return
    
    try {
      const response = await fetch(`http://localhost:8080/api/v1/me`, {
        headers: {
          'Authorization': `Bearer ${token.value}`,
          'X-Tenant-ID': 'default-tenant-id'
        }
      })

      if (response.ok) {
        const data = await response.json()
        user.value = data.user
        if (data.tenant && data.tenant.subscription_tier) {
          subscriptionTier.value = data.tenant.subscription_tier
        }
      } else {
        if (response.status === 401) {
          logout()
        }
      }
    } catch (e) {
      console.error('Failed to fetch user', e)
    }
  }

  function logout() {
    token.value = null
    user.value = null
    role.value = null
    subscriptionTier.value = 'normal'
    localStorage.removeItem('token')
    router.push('/login')
  }

  return {
    token,
    user,
    role,
    subscriptionTier,
    isAuthenticated,
    isSuperAdmin,
    isLoading,
    error,
    login,
    register,
    logout,
    fetchUser
  }
})
