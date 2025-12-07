<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminStore } from '@/stores/admin'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Building2, Users, TrendingUp, Plus, LogIn, CreditCard } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { getTenantUrl, config } from '@/config/env'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Label } from '@/components/ui/label'

const router = useRouter()
const adminStore = useAdminStore()

const showSubscriptionDialog = ref(false)
const selectedTenant = ref<Tenant | null>(null)
const selectedTier = ref('normal')
const isUpdating = ref(false)

onMounted(async () => {
  await Promise.all([
    adminStore.fetchStats(),
    adminStore.fetchTenants()
  ])
})

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const getSubdomainUrl = (subdomain: string) => {
  return getTenantUrl(subdomain)
}

interface Tenant {
  id: string
  name: string
  subdomain: string
  db_name: string
  created_at: string
  subscription_tier?: string
}

const handleImpersonate = async (tenant: Tenant) => {
  try {
    const token = await adminStore.impersonateTenant(tenant.id)
    
    // Save the impersonation token
    localStorage.setItem('token', token)
    
    // Reload the page to refresh the auth state
    // The user will now be logged in as the tenant owner
    window.location.href = '/dashboard'
  } catch (e: any) {
    toast.error('Failed to login as owner', {
      description: e.message
    })
  }
}

const openSubscriptionDialog = (tenant: Tenant) => {
  selectedTenant.value = tenant
  selectedTier.value = tenant.subscription_tier || 'normal'
  showSubscriptionDialog.value = true
}

const handleUpdateSubscription = async () => {
  if (!selectedTenant.value) return

  isUpdating.value = true
  try {
    await adminStore.updateSubscription(selectedTenant.value.id, selectedTier.value)
    toast.success('Subscription updated', {
      description: `Updated ${selectedTenant.value.name} to ${selectedTier.value} tier`
    })
    showSubscriptionDialog.value = false
  } catch (e: any) {
    toast.error('Failed to update subscription', {
      description: e.message
    })
  } finally {
    isUpdating.value = false
  }
}

const getTierBadgeColor = (tier?: string) => {
  switch (tier) {
    case 'premium': return 'bg-purple-100 text-purple-800'
    case 'pro': return 'bg-blue-100 text-blue-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-col bg-muted/40 p-6">
    <div class="mx-auto w-full max-w-7xl space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold tracking-tight">Super Admin Dashboard</h1>
          <p class="text-muted-foreground">Manage your car rental platform</p>
        </div>
        <Button @click="router.push('/dashboard/admin/tenants/new')" size="lg">
          <Plus class="mr-2 h-4 w-4" />
          Create New Shop
        </Button>
      </div>

      <!-- Stats Cards -->
      <div class="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle class="text-sm font-medium">Total Shops</CardTitle>
            <Building2 class="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div class="text-2xl font-bold">{{ adminStore.stats?.total_tenants || 0 }}</div>
            <p class="text-xs text-muted-foreground">All registered car rental shops</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle class="text-sm font-medium">Active Shops</CardTitle>
            <Users class="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div class="text-2xl font-bold">{{ adminStore.stats?.active_tenants || 0 }}</div>
            <p class="text-xs text-muted-foreground">Currently operational</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle class="text-sm font-medium">New This Month</CardTitle>
            <TrendingUp class="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div class="text-2xl font-bold">{{ adminStore.stats?.new_this_month || 0 }}</div>
            <p class="text-xs text-muted-foreground">Shops created this month</p>
          </CardContent>
        </Card>
      </div>

      <!-- Recent Tenants -->
      <Card>
        <CardHeader>
          <CardTitle>All Shops</CardTitle>
          <CardDescription>Manage your car rental shop tenants</CardDescription>
        </CardHeader>
        <CardContent>
          <div v-if="adminStore.isLoading" class="text-center py-8">
            Loading...
          </div>
          <div v-else-if="adminStore.error" class="text-center py-8 text-destructive">
            Error: {{ adminStore.error }}
          </div>
          <div v-else-if="!adminStore.tenants.length" class="text-center py-8 text-muted-foreground">
            No shops created yet
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="tenant in adminStore.tenants"
              :key="tenant.id"
              class="flex items-center justify-between border-b pb-4 last:border-0"
            >
              <div class="space-y-1">
                <div class="flex items-center gap-2">
                  <p class="font-medium">{{ tenant.name }}</p>
                  <span 
                    class="rounded-full px-2 py-0.5 text-[10px] font-medium uppercase"
                    :class="getTierBadgeColor(tenant.subscription_tier)"
                  >
                    {{ tenant.subscription_tier || 'normal' }}
                  </span>
                </div>
                <div class="flex items-center gap-2 text-sm text-muted-foreground">
                  <a
                    :href="getSubdomainUrl(tenant.subdomain)"
                    target="_blank"
                    class="hover:underline hover:text-primary"
                  >
                    {{ getSubdomainUrl(tenant.subdomain).replace('http://', '').replace('https://', '') }}
                  </a>
                  <span>•</span>
                  <span>Created {{ formatDate(tenant.created_at) }}</span>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <Button variant="outline" size="sm" @click="openSubscriptionDialog(tenant)">
                  <CreditCard class="mr-2 h-4 w-4" />
                  Manage Plan
                </Button>
                <Button variant="outline" size="sm" @click="handleImpersonate(tenant)">
                  <LogIn class="mr-2 h-4 w-4" />
                  Login as Owner
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Subscription Dialog -->
    <Dialog v-model:open="showSubscriptionDialog">
      <DialogContent class="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Manage Subscription</DialogTitle>
          <DialogDescription>
            Update the subscription plan for {{ selectedTenant?.name }}. This will immediately affect available features.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <Label>Subscription Tier</Label>
            <Select v-model="selectedTier">
              <SelectTrigger>
                <SelectValue placeholder="Select a tier" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="normal">
                  <div class="flex items-center">
                    <span class="font-medium">Normal</span>
                    <span class="ml-2 text-xs text-muted-foreground">(Basic features)</span>
                  </div>
                </SelectItem>
                <SelectItem value="pro">
                  <div class="flex items-center">
                    <span class="font-medium">Pro</span>
                    <span class="ml-2 text-xs text-muted-foreground">(Advanced reports)</span>
                  </div>
                </SelectItem>
                <SelectItem value="premium">
                  <div class="flex items-center">
                    <span class="font-medium">Premium</span>
                    <span class="ml-2 text-xs text-muted-foreground">(All features)</span>
                  </div>
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showSubscriptionDialog = false">Cancel</Button>
          <Button @click="handleUpdateSubscription" :disabled="isUpdating">
            {{ isUpdating ? 'Updating...' : 'Save Changes' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
