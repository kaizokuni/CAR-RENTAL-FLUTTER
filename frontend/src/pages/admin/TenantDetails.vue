<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminStore } from '@/stores/admin'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowLeft, Building2, Calendar, Database, Globe, Mail, Shield, Trash2, LogIn, CreditCard } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
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

const route = useRoute()
const router = useRouter()
const adminStore = useAdminStore()

const tenantId = route.params.id as string
const tenant = ref<any>(null)
const isLoading = ref(true)
const showDeleteDialog = ref(false)
const showSubscriptionDialog = ref(false)
const selectedTier = ref('normal')
const isUpdating = ref(false)
const isDeleting = ref(false)

onMounted(async () => {
  await fetchTenantDetails()
})

const fetchTenantDetails = async () => {
  isLoading.value = true
  try {
    // We can reuse fetchTenants and find the specific one, or add a getTenantById action
    // For now, let's ensure the list is loaded and find it
    if (adminStore.tenants.length === 0) {
      await adminStore.fetchTenants()
    }
    tenant.value = adminStore.tenants.find((t: any) => t.id === tenantId)
    
    if (!tenant.value) {
      toast.error('Tenant not found')
      router.push('/dashboard/admin/dashboard')
    } else {
      selectedTier.value = tenant.value.subscription_tier || 'normal'
    }
  } catch (e: any) {
    toast.error('Failed to load tenant details')
  } finally {
    isLoading.value = false
  }
}

const formatDate = (dateString: string) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getSubdomainUrl = (subdomain: string) => {
  return `http://${subdomain}.localhost:5173`
}

const handleImpersonate = async () => {
  if (!tenant.value) return
  try {
    const token = await adminStore.impersonateTenant(tenant.value.id)
    localStorage.setItem('token', token)
    window.location.href = '/dashboard'
  } catch (e: any) {
    toast.error('Failed to login as owner', { description: e.message })
  }
}

const handleUpdateSubscription = async () => {
  if (!tenant.value) return
  isUpdating.value = true
  try {
    await adminStore.updateSubscription(tenant.value.id, selectedTier.value)
    toast.success('Subscription updated')
    showSubscriptionDialog.value = false
    // Refresh details
    await adminStore.fetchTenants()
    tenant.value = adminStore.tenants.find((t: any) => t.id === tenantId)
  } catch (e: any) {
    toast.error('Failed to update subscription', { description: e.message })
  } finally {
    isUpdating.value = false
  }
}

const handleDeleteTenant = async () => {
  if (!tenant.value) return
  isDeleting.value = true
  try {
    await adminStore.deleteTenant(tenant.value.id)
    toast.success('Tenant deleted successfully')
    router.push('/dashboard/admin/dashboard')
  } catch (e: any) {
    toast.error('Failed to delete tenant', { description: e.message })
  } finally {
    isDeleting.value = false
    showDeleteDialog.value = false
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
    <div class="mx-auto w-full max-w-5xl space-y-6">
      <!-- Header -->
      <div class="flex items-center gap-4">
        <Button variant="outline" size="icon" @click="router.back()">
          <ArrowLeft class="h-4 w-4" />
        </Button>
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Tenant Details</h1>
          <p class="text-muted-foreground">View and manage shop information</p>
        </div>
      </div>

      <div v-if="isLoading" class="text-center py-12">
        Loading...
      </div>

      <div v-else-if="tenant" class="grid gap-6 md:grid-cols-2">
        <!-- Main Info Card -->
        <Card class="md:col-span-2">
          <CardHeader>
            <div class="flex items-start justify-between">
              <div>
                <CardTitle class="text-2xl">{{ tenant.name }}</CardTitle>
                <CardDescription class="mt-2 flex items-center gap-2">
                  <Globe class="h-4 w-4" />
                  <a :href="getSubdomainUrl(tenant.subdomain)" target="_blank" class="hover:underline text-primary">
                    {{ tenant.subdomain }}.localhost:5173
                  </a>
                </CardDescription>
              </div>
              <span 
                class="rounded-full px-3 py-1 text-sm font-medium uppercase"
                :class="getTierBadgeColor(tenant.subscription_tier)"
              >
                {{ tenant.subscription_tier || 'normal' }}
              </span>
            </div>
          </CardHeader>
          <CardContent class="space-y-6">
            <div class="grid gap-4 md:grid-cols-2">
              <div class="space-y-1">
                <Label class="text-muted-foreground">Database Name</Label>
                <div class="flex items-center gap-2 font-medium">
                  <Database class="h-4 w-4 text-muted-foreground" />
                  {{ tenant.db_name }}
                </div>
              </div>
              <div class="space-y-1">
                <Label class="text-muted-foreground">Created At</Label>
                <div class="flex items-center gap-2 font-medium">
                  <Calendar class="h-4 w-4 text-muted-foreground" />
                  {{ formatDate(tenant.created_at) }}
                </div>
              </div>
            </div>

            <div class="flex flex-wrap gap-3 pt-4 border-t">
              <Button @click="handleImpersonate">
                <LogIn class="mr-2 h-4 w-4" />
                Login as Owner
              </Button>
              <Button variant="outline" @click="showSubscriptionDialog = true">
                <CreditCard class="mr-2 h-4 w-4" />
                Manage Subscription
              </Button>
              <Button variant="destructive" @click="showDeleteDialog = true">
                <Trash2 class="mr-2 h-4 w-4" />
                Delete Tenant
              </Button>
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
              Update the subscription plan for {{ tenant?.name }}.
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
                  <SelectItem value="normal">Normal (Basic)</SelectItem>
                  <SelectItem value="pro">Pro (Advanced)</SelectItem>
                  <SelectItem value="premium">Premium (All Features)</SelectItem>
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

      <!-- Delete Confirmation Dialog -->
      <Dialog v-model:open="showDeleteDialog">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Tenant</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete <strong>{{ tenant?.name }}</strong>? This action cannot be undone.
              All data associated with this tenant will be permanently removed.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="showDeleteDialog = false">Cancel</Button>
            <Button variant="destructive" @click="handleDeleteTenant" :disabled="isDeleting">
              {{ isDeleting ? 'Deleting...' : 'Delete Tenant' }}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </div>
</template>
