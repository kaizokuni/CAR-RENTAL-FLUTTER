import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface StaffMember {
  id: string
  email: string
  first_name: string
  last_name: string
  role_id: string
  role_name: string
  created_at: string
}

export interface Role {
  id: string
  name: string
  description: string
}

export interface CreateStaffData {
  email: string
  password: string
  first_name: string
  last_name: string
  role_id: string
}

export interface UpdateStaffData {
  email?: string
  first_name?: string
  last_name?: string
  role_id?: string
  password?: string
}

export const useStaffStore = defineStore('staff', () => {
  const staff = ref<StaffMember[]>([])
  const roles = ref<Role[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const authStore = useAuthStore()

  const getAuthHeaders = () => ({
    'Authorization': `Bearer ${authStore.token}`,
    'Content-Type': 'application/json'
  })

  const fetchStaff = async () => {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch('/api/v1/staff', {
        headers: getAuthHeaders()
      })
      if (!response.ok) throw new Error('Failed to fetch staff')
      const data = await response.json()
      console.log('Staff API response:', data)
      staff.value = data
    } catch (e) {
      error.value = (e as Error).message
      console.error('Staff fetch error:', e)
    } finally {
      isLoading.value = false
    }
  }

  const fetchRoles = async () => {
    try {
      const response = await fetch('/api/v1/roles', {
        headers: getAuthHeaders()
      })
      if (!response.ok) throw new Error('Failed to fetch roles')
      roles.value = await response.json()
    } catch (e) {
      console.error('Failed to fetch roles:', e)
    }
  }

  const createStaff = async (data: CreateStaffData) => {
    const response = await fetch('/api/v1/staff', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    })
    if (!response.ok) {
      const err = await response.json()
      throw new Error(err.error || 'Failed to create staff')
    }
    await fetchStaff()
    return await response.json()
  }

  const updateStaff = async (id: string, data: UpdateStaffData) => {
    const response = await fetch(`/api/v1/staff/${id}`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    })
    if (!response.ok) {
      const err = await response.json()
      throw new Error(err.error || 'Failed to update staff')
    }
    await fetchStaff()
    return await response.json()
  }

  const deleteStaff = async (id: string) => {
    const response = await fetch(`/api/v1/staff/${id}`, {
      method: 'DELETE',
      headers: getAuthHeaders()
    })
    if (!response.ok) {
      const err = await response.json()
      throw new Error(err.error || 'Failed to delete staff')
    }
    await fetchStaff()
  }

  return {
    staff,
    roles,
    isLoading,
    error,
    fetchStaff,
    fetchRoles,
    createStaff,
    updateStaff,
    deleteStaff
  }
})
