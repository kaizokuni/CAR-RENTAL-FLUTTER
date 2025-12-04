import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'

export interface Notification {
  id: string
  title: string
  message: string
  type: 'info' | 'warning' | 'success' | 'error'
  is_read: boolean
  created_at: string
}

export const useNotificationsStore = defineStore('notifications', () => {
  const notifications = ref<Notification[]>([])
  const isLoading = ref(false)
  const authStore = useAuthStore()

  const unreadCount = computed(() => notifications.value.filter(n => !n.is_read).length)

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

  async function fetchNotifications() {
    isLoading.value = true
    try {
      const response = await fetch(`${API_URL}/notifications`, {
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch notifications')
      notifications.value = await response.json()
    } catch (e) {
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  async function markAsRead(id: string) {
    try {
      // Optimistic update
      const notif = notifications.value.find(n => n.id === id)
      if (notif) notif.is_read = true

      const response = await fetch(`${API_URL}/notifications/${id}/read`, {
        method: 'PUT',
        headers: getHeaders(),
      })
      if (!response.ok) throw new Error('Failed to mark as read')
    } catch (e) {
      console.error(e)
      // Revert if failed (optional, but good practice)
    }
  }

  return {
    notifications,
    unreadCount,
    isLoading,
    fetchNotifications,
    markAsRead
  }
})
