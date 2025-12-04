import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface Expense {
  id: string
  amount: number
  category: string
  date: string
  description: string
}

export interface Invoice {
  id: string
  booking_id: string
  amount: number
  status: string
  issued_date: string
  due_date?: string
  customer_name?: string
}

export interface RevenueStats {
  total_revenue: number
  total_expenses: number
  net_profit: number
}

export const useFinancialsStore = defineStore('financials', () => {
  const expenses = ref<Expense[]>([])
  const invoices = ref<Invoice[]>([])
  const stats = ref<RevenueStats | null>(null)
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

  async function fetchExpenses() {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/financials/expenses`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch expenses')
      expenses.value = await response.json()
    } catch (e: any) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  async function createExpense(expenseData: Omit<Expense, 'id'>) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/financials/expenses`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(expenseData),
      })
      if (!response.ok) throw new Error('Failed to create expense')
      await fetchExpenses()
      await fetchStats() // Refresh stats
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function fetchInvoices() {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/financials/invoices`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch invoices')
      invoices.value = await response.json()
    } catch (e: any) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  async function generateInvoice(data: { booking_id: string, amount: number, due_date: string }) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/financials/invoices`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(data),
      })
      if (!response.ok) throw new Error('Failed to generate invoice')
      await fetchInvoices()
      await fetchStats() // Refresh stats
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function fetchStats() {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_URL}/financials/stats`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch stats')
      stats.value = await response.json()
    } catch (e: any) {
      error.value = e.message
    } finally {
      isLoading.value = false
    }
  }

  return {
    expenses,
    invoices,
    stats,
    isLoading,
    error,
    fetchExpenses,
    createExpense,
    fetchInvoices,
    generateInvoice,
    fetchStats
  }
})
