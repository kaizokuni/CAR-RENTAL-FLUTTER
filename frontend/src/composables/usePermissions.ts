import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

export function usePermissions() {
  const authStore = useAuthStore()

  const userRole = computed(() => authStore.role)
  const isSuperAdmin = computed(() => authStore.isSuperAdmin)

  // Check if user has a specific role
  const hasRole = (role: string): boolean => {
    return userRole.value === role
  }

  // Check if user has permission (future: check against permissions array)
  const hasPermission = (permission: string): boolean => {
    // Super admin has all permissions
    if (isSuperAdmin.value) return true

    // TODO: In future, check user.permissions.includes(permission)
    // For now, basic role-based checks
    const rolePermissions: Record<string, string[]> = {
      'admin': ['cars:*', 'bookings:*', 'customers:*', 'staff:manage', 'reports:view'],
      'manager': ['cars:*', 'bookings:*', 'customers:read'],
      'assistant': ['cars:read', 'bookings:create', 'bookings:read', 'customers:read']
    }

    const permissions = rolePermissions[userRole.value || ''] || []
    
    // Check wildcard permissions
    if (permissions.includes('*')) return true
    if (permissions.includes(permission)) return true
    
    // Check wildcard in category (e.g., 'cars:*' allows 'cars:read', 'cars:write')
    const [category] = permission.split(':')
    if (permissions.includes(`${category}:*`)) return true

    return false
  }

  // Check if user's tenant has a specific subscription tier
  const hasSubscription = (minTier: string): boolean => {
    // Super admin bypasses subscription checks
    if (isSuperAdmin.value) return true

    const currentTier = authStore.subscriptionTier || 'normal'
    
    const tierLevels: Record<string, number> = {
      'normal': 1,
      'pro': 2,
      'premium': 3
    }

    return (tierLevels[currentTier] || 0) >= (tierLevels[minTier] || 0)
  }

  // Check if feature is available based on role and subscription
  const canAccess = (requiredRole?: string, requiredSubscription?: string): boolean => {
    if (requiredRole && !hasRole(requiredRole) && !isSuperAdmin.value) {
      return false
    }

    if (requiredSubscription && !hasSubscription(requiredSubscription)) {
      return false
    }

    return true
  }

  return {
    userRole,
    isSuperAdmin,
    hasRole,
    hasPermission,
    hasSubscription,
    canAccess
  }
}
