import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

interface Tenant {
  id: string
  name: string
  subdomain: string
  db_name: string
  created_at: string
  subscription_tier?: string
}

interface AdminStats {
  total_tenants: number
  active_tenants: number
  new_this_month: number
}

export const useAdminStore = defineStore('admin', () => {
  const tenants = ref<Tenant[]>([])
  const stats = ref<AdminStats | null>(null)
  const isLoading = ref(false)
  const error = ref('')

  const authStore = useAuthStore()

  const API_URL = `http://localhost:8080/api/v1/admin`

  async function fetchTenants() {
    isLoading.value = true
    error.value = ''

    try {
      const response = await fetch(`${API_URL}/tenants`, {
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch tenants')
      }

      const data = await response.json()
      tenants.value = data || []
    } catch (e: any) {
      error.value = e.message
      tenants.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function fetchStats() {
    isLoading.value = true
    error.value = ''

    try {
      const response = await fetch(`${API_URL}/stats`, {
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch stats')
      }

      stats.value = await response.json()
    } catch (e: any) {
      error.value = e.message
      stats.value = null
    } finally {
      isLoading.value = false
    }
  }

  async function deleteTenant(id: string) {
    error.value = ''

    try {
      const response = await fetch(`${API_URL}/tenants/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to delete tenant')
      }

      // Refresh the list
      await fetchTenants()
      await fetchStats()
      await fetchStats()
    } catch (e: any) {
      error.value = e.message
      throw e
    }
  }

  async function impersonateTenant(id: string) {
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/tenants/${id}/impersonate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to impersonate tenant')
      }

      const data = await response.json()
      return data.token
    } catch (e: any) {
      error.value = e.message
      throw e
    }
  }

  return {
    tenants,
    stats,
    isLoading,
    error,
    fetchTenants,
    fetchStats,
    deleteTenant,
    impersonateTenant,
    updateSubscription
  }

  async function updateSubscription(id: string, tier: string) {
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/tenants/${id}/subscription`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ tier })
      })

      if (!response.ok) {
        throw new Error('Failed to update subscription')
      }

      await fetchTenants() // Refresh list
    } catch (e: any) {
      error.value = e.message
      throw e
    }
  }
})
