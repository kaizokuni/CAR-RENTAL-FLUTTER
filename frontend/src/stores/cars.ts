import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface Car {
  id: string
  make: string
  model: string
  year: number
  license_plate: string
  status: 'available' | 'rented' | 'maintenance'
  price_per_day: number
  image_url?: string
}

export const useCarsStore = defineStore('cars', () => {
  const cars = ref<Car[]>([])
  const isLoading = ref(false)
  const error = ref('')

  const authStore = useAuthStore()
  // Use localhost:8080 for backend API
  const API_URL = 'http://localhost:8080/api/v1'

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
    createCar
  }
})
