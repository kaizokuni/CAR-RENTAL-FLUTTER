import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface Booking {
  id: string
  car_id: string
  customer_id: string // Simplified for now, backend might return object
  car_make?: string // Joined fields
  car_model?: string
  customer_name?: string
  start_date: string
  end_date: string
  status: string
  total_price: number
}

export const useBookingsStore = defineStore('bookings', () => {
  const bookings = ref<Booking[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
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

  async function fetchBookings() {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/bookings`, {
        headers: getHeaders(),
      })

      if (!response.ok) {
        throw new Error('Failed to fetch bookings')
      }

      bookings.value = await response.json()
    } catch (e: any) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  async function createBooking(bookingData: any) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/bookings`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(bookingData),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Failed to create booking')
      }

      await fetchBookings()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function updateStatus(id: string, status: string) {
    isLoading.value = true
    try {
        const response = await fetch(`${API_URL}/bookings/${id}/status`, {
            method: 'PUT',
            headers: getHeaders(),
            body: JSON.stringify({ status })
        })
        if (!response.ok) throw new Error('Failed to update status')
        await fetchBookings()
    } catch (e: any) {
        error.value = e.message
    } finally {
        isLoading.value = false
    }
  }

  return {
    bookings,
    isLoading,
    error,
    fetchBookings,
    createBooking,
    updateStatus
  }
})
