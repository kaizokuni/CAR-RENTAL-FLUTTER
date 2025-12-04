import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface Customer {
  id: string
  first_name: string
  last_name: string
  email: string
  phone: string
  license_number: string
  address: string
}

export const useCustomersStore = defineStore('customers', () => {
  const customers = ref<Customer[]>([])
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

  async function fetchCustomers() {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/customers`, {
        headers: getHeaders(),
      })

      if (!response.ok) {
        throw new Error('Failed to fetch customers')
      }

      customers.value = await response.json()
    } catch (e: any) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  async function createCustomer(customerData: Omit<Customer, 'id'>) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/customers`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(customerData),
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Failed to create customer')
      }

      await fetchCustomers()
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  return {
    customers,
    isLoading,
    error,
    fetchCustomers,
    createCustomer
  }
})
