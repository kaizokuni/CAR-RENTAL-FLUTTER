import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'
import { getApiEndpoint } from '@/config/env'

export interface Car {
  id: string
  brand: string
  model: string
  year: number
  license_plate: string
  status: 'available' | 'rented' | 'maintenance'
  price_per_day: number
  category?: string
  currency?: string
  images?: string[]
  image_url?: string  // Kept for backward compatibility
  transmission?: 'automatic' | 'manual'
  fuel_type?: 'electric' | 'hybrid_plugin' | 'hybrid' | 'gasoline' | 'diesel'
  seats?: number
  description?: string
  created_at?: string
}

export const useCarsStore = defineStore('cars', () => {
  const cars = ref<Car[]>([])
  const isLoading = ref(false)
  const error = ref('')

  const authStore = useAuthStore()
  const API_URL = getApiEndpoint('/api/v1')

  async function fetchCars() {
    isLoading.value = true
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/cars`, {
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch cars')
      }

      const data = await response.json()
      cars.value = data || []
    } catch (e: any) {
      error.value = e.message
      cars.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function createCar(car: Omit<Car, 'id' | 'status'>) {
    isLoading.value = true
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/cars`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(car)
      })

      if (!response.ok) {
        throw new Error('Failed to create car')
      }

      await fetchCars() // Refresh list
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  return {
    cars,
    isLoading,
    error,
    fetchCars,
    createCar,
    updateCar,
    deleteCar
  }

  async function updateCar(id: string, car: Partial<Car>) {
    isLoading.value = true
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/cars/${id}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(car)
      })

      if (!response.ok) {
        throw new Error('Failed to update car')
      }

      await fetchCars()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function deleteCar(id: string) {
    isLoading.value = true
    error.value = ''
    try {
      const response = await fetch(`${API_URL}/cars/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${authStore.token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to delete car')
      }

      await fetchCars()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }
})
