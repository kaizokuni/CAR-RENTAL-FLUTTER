<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue-sonner'
import { Upload, ArrowLeft } from 'lucide-vue-next'

const router = useRouter()
const authStore = useAuthStore()
const name = ref('')
const subdomain = ref('')
const adminEmail = ref('')
const adminPassword = ref('')
const logoFile = ref<File | null>(null)
const logoPreview = ref<string | null>(null)
const isLoading = ref(false)

const handleLogoChange = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  if (file) {
    if (!file.type.startsWith('image/')) {
      toast.error('Please upload an image file')
      return
    }
    
    if (file.size > 2 * 1024 * 1024) { // 2MB limit
      toast.error('Logo must be less than 2MB')
      return
    }
    
    logoFile.value = file
    
    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      logoPreview.value = e.target?.result as string
    }
    reader.readAsDataURL(file)
  }
}

const handleCreateTenant = async () => {
  isLoading.value = true

  try {
    const token = authStore.token
    if (!token) {
      throw new Error('You must be logged in as Super Admin')
    }

    const API_URL = `http://${window.location.hostname}:8080/api/v1/admin/tenants`

    // For now, we'll send tenant data without logo
    // Logo upload can be implemented later with multipart/form-data
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        name: name.value,
        subdomain: subdomain.value,
        admin_email: adminEmail.value,
        admin_password: adminPassword.value
      })
    })

    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create tenant')
    }

    // Show success toast
    toast.success('Shop Created Successfully!', {
      description: `${name.value} is now ready to use at ${subdomain.value}.localhost:5173`
    })

    // Wait a bit for user to see the toast, then redirect
    setTimeout(() => {
      router.push('/dashboard/admin/dashboard')
    }, 1500)
  } catch (e: any) {
    toast.error('Failed to Create Shop', {
      description: e.message
    })
  } finally {
    isLoading.value = false
  }
}

const goBack = () => {
  router.push('/dashboard/admin/dashboard')
}
</script>

<template>
  <div class="flex min-h-screen flex-col bg-muted/40 p-6">
    <div class="mx-auto w-full max-w-2xl space-y-6">
      <!-- Back Button -->
      <Button variant="ghost" @click="goBack" class="w-fit">
        <ArrowLeft class="mr-2 h-4 w-4" />
        Back to Dashboard
      </Button>

      <Card>
        <CardHeader>
          <CardTitle class="text-2xl">
            Create New Shop
          </CardTitle>
          <CardDescription>
            Set up a new car rental business environment with its own database and admin account.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="handleCreateTenant">
            <div class="grid gap-6">
              <!-- Shop Logo Upload -->
              <div class="grid gap-2">
                <Label>Shop Logo (Optional)</Label>
                <div class="flex items-start gap-4">
                  <div class="flex-1">
                    <div class="border-2 border-dashed rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer relative">
                      <input
                        type="file"
                        accept="image/*"
                        class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                        @change="handleLogoChange"
                        :disabled="isLoading"
                      />
                      <div v-if="!logoPreview" class="space-y-2">
                        <Upload class="mx-auto h-8 w-8 text-muted-foreground" />
                        <div class="text-sm text-muted-foreground">
                          <span class="font-semibold text-primary">Click to upload</span> or drag and drop
                        </div>
                        <p class="text-xs text-muted-foreground">PNG, JPG up to 2MB</p>
                      </div>
                      <div v-else class="space-y-2">
                        <img :src="logoPreview" alt="Logo preview" class="mx-auto h-20 w-20 object-contain rounded" />
                        <p class="text-xs text-muted-foreground">Click to change</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Shop Name -->
              <div class="grid gap-2">
                <Label for="name">Shop Name *</Label>
                <Input 
                  id="name" 
                  v-model="name" 
                  placeholder="Avis Car Rental" 
                  required 
                  :disabled="isLoading" 
                />
              </div>

              <!-- Subdomain -->
              <div class="grid gap-2">
                <Label for="subdomain">Subdomain *</Label>
                <div class="flex items-center gap-2">
                  <Input 
                    id="subdomain" 
                    v-model="subdomain" 
                    placeholder="avis" 
                    required 
                    :disabled="isLoading"
                    pattern="[a-z0-9-]+"
                    title="Only lowercase letters, numbers, and hyphens"
                  />
                  <span class="text-sm text-muted-foreground whitespace-nowrap">.localhost:5173</span>
                </div>
                <p class="text-xs text-muted-foreground">Only lowercase letters, numbers, and hyphens</p>
              </div>
              
              <!-- Admin Email -->
              <div class="grid gap-2">
                <Label for="adminEmail">Admin Email *</Label>
                <Input 
                  id="adminEmail" 
                  v-model="adminEmail" 
                  type="email" 
                  placeholder="admin@avis.com" 
                  required 
                  :disabled="isLoading" 
                />
                <p class="text-xs text-muted-foreground">This will be used to login to the shop dashboard</p>
              </div>

              <!-- Admin Password -->
              <div class="grid gap-2">
                <Label for="adminPassword">Admin Password *</Label>
                <Input 
                  id="adminPassword" 
                  v-model="adminPassword" 
                  type="password" 
                  required 
                  :disabled="isLoading"
                  minlength="8"
                />
                <p class="text-xs text-muted-foreground">Minimum 8 characters</p>
              </div>

              <!-- Submit Button -->
              <div class="flex gap-3">
                <Button 
                  type="button" 
                  variant="outline" 
                  class="flex-1" 
                  @click="goBack"
                  :disabled="isLoading"
                >
                  Cancel
                </Button>
                <Button type="submit" class="flex-1" :disabled="isLoading">
                  <span v-if="isLoading">Creating Shop...</span>
                  <span v-else>Create Shop</span>
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
