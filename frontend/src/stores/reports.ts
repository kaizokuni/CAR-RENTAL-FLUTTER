import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface UtilizationStat {
  date: string
  percentage: number
}

export interface RevenueByCar {
  car_id: string
  make: string
  model: string
  total_revenue: number
  booking_count: number
}

export const useReportsStore = defineStore('reports', () => {
  const utilization = ref<UtilizationStat[]>([])
  const revenueByCar = ref<RevenueByCar[]>([])
  const isLoading = ref(false)
  const authStore = useAuthStore()

  const getHeaders = () => {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    }
    if (authStore.token) {
      headers['Authorization'] = `Bearer ${authStore.token}`
    }
    return headers
  }

  const API_URL = `http://${window.location.hostname}:8080/api/v1`

  async function fetchUtilization() {
    isLoading.value = true
    try {
      const response = await fetch(`${API_URL}/reports/utilization`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch utilization')
      utilization.value = await response.json()
    } catch (e) {
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchRevenueByCar() {
    isLoading.value = true
    try {
      const response = await fetch(`${API_URL}/reports/revenue-by-car`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch revenue stats')
      revenueByCar.value = await response.json()
    } catch (e) {
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  return {
    utilization,
    revenueByCar,
    isLoading,
    fetchUtilization,
    fetchRevenueByCar
  }
})
