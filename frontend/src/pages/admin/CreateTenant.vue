<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue-sonner'
import { Upload, ArrowLeft, Check, CreditCard, Banknote, Store, ShieldCheck, AlertCircle } from 'lucide-vue-next'
import { getApiEndpoint, config } from '@/config/env'
import TenantCreatedSuccess from '@/components/admin/TenantCreatedSuccess.vue'

const router = useRouter()
const authStore = useAuthStore()

// Wizard State
const currentStep = ref(1)
const totalSteps = 3
const isLoading = ref(false)
const showSuccessDialog = ref(false)

// Form Data
const name = ref('')
const logoFile = ref<File | null>(null)
const logoPreview = ref<string | null>(null)

const subscriptionTier = ref('normal')
const paymentMethod = ref('online')

const subdomain = ref('')
const adminEmail = ref('')
const adminPassword = ref('')

// Validation Error States
const errors = ref({
  name: '',
  subdomain: '',
  adminEmail: '',
  adminPassword: '',
  logo: ''
})

// Validation Functions
const validateName = () => {
  if (!name.value.trim()) {
    errors.value.name = 'Shop name is required'
    return false
  }
  if (name.value.trim().length < 3) {
    errors.value.name = 'Shop name must be at least 3 characters'
    return false
  }
  errors.value.name = ''
  return true
}

const validateSubdomain = () => {
  if (!subdomain.value.trim()) {
    errors.value.subdomain = 'Subdomain is required'
    return false
  }
  const subdomainRegex = /^[a-z0-9-]+$/
  if (!subdomainRegex.test(subdomain.value)) {
    errors.value.subdomain = 'Only lowercase letters, numbers, and hyphens allowed'
    return false
  }
  if (subdomain.value.length < 3) {
    errors.value.subdomain = 'Subdomain must be at least 3 characters'
    return false
  }
  if (subdomain.value.startsWith('-') || subdomain.value.endsWith('-')) {
    errors.value.subdomain = 'Subdomain cannot start or end with a hyphen'
    return false
  }
  errors.value.subdomain = ''
  return true
}

const validateEmail = () => {
  if (!adminEmail.value.trim()) {
    errors.value.adminEmail = 'Admin email is required'
    return false
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(adminEmail.value)) {
    errors.value.adminEmail = 'Please enter a valid email address'
    return false
  }
  errors.value.adminEmail = ''
  return true
}

const validatePassword = () => {
  if (!adminPassword.value) {
    errors.value.adminPassword = 'Admin password is required'
    return false
  }
  if (adminPassword.value.length < 8) {
    errors.value.adminPassword = 'Password must be at least 8 characters'
    return false
  }
  if (!/[A-Z]/.test(adminPassword.value)) {
    errors.value.adminPassword = 'Password must contain at least one uppercase letter'
    return false
  }
  if (!/[a-z]/.test(adminPassword.value)) {
    errors.value.adminPassword = 'Password must contain at least one lowercase letter'
    return false
  }
  if (!/[0-9]/.test(adminPassword.value)) {
    errors.value.adminPassword = 'Password must contain at least one number'
    return false
  }
  errors.value.adminPassword = ''
  return true
}

// Auto-generate subdomain from name
watch(name, (newName) => {
  if (currentStep.value === 1 && !subdomain.value) {
    subdomain.value = newName.toLowerCase()
      .replace(/[^a-z0-9-]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '')
  }
})

// Clear errors when user types
watch(name, () => { if (errors.value.name) validateName() })
watch(subdomain, () => { if (errors.value.subdomain) validateSubdomain() })
watch(adminEmail, () => { if (errors.value.adminEmail) validateEmail() })
watch(adminPassword, () => { if (errors.value.adminPassword) validatePassword() })

const handleLogoChange = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  errors.value.logo = ''
  
  if (file) {
    if (!file.type.startsWith('image/')) {
      errors.value.logo = 'Please upload an image file (PNG, JPG, etc.)'
      toast.error('Invalid file type', {
        description: 'Please upload an image file'
      })
      return
    }
    
    if (file.size > 2 * 1024 * 1024) { // 2MB limit
      errors.value.logo = 'Logo must be less than 2MB'
      toast.error('File too large', {
        description: 'Logo must be less than 2MB'
      })
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

const validateCurrentStep = () => {
  if (currentStep.value === 1) {
    return validateName()
  } else if (currentStep.value === 3) {
    return validateSubdomain() && validateEmail() && validatePassword()
  }
  return true
}

const nextStep = () => {
  if (!validateCurrentStep()) {
    toast.error('Please fix the errors', {
      description: 'Check the highlighted fields and try again'
    })
    return
  }
  
  if (currentStep.value < totalSteps) {
    currentStep.value++
  }
}

const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

const handleCreateTenant = async () => {
  // Final validation
  if (!validateName() || !validateSubdomain() || !validateEmail() || !validatePassword()) {
    toast.error('Please fix all validation errors', {
      description: 'All fields must be filled correctly before submitting'
    })
    return
  }

  isLoading.value = true

  try {
    const token = authStore.token
    if (!token) {
      throw new Error('You must be logged in as Super Admin')
    }

    const API_URL = getApiEndpoint('/api/v1/admin/tenants')

    const formData = new FormData()
    formData.append('name', name.value.trim())
    formData.append('subdomain', subdomain.value.trim())
    formData.append('admin_email', adminEmail.value.trim())
    formData.append('admin_password', adminPassword.value)
    formData.append('tier', subscriptionTier.value)
    formData.append('payment_method', paymentMethod.value)
    
    if (logoFile.value) {
      formData.append('logo', logoFile.value)
    }

    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    })

    const data = await response.json()

    if (!response.ok) {
      // Extract user-friendly error message from backend response
      let errorMessage = 'Failed to create shop'
      
      if (data.error) {
        // Handle validation errors
        const match = data.error.match(/Field validation for '(\w+)' failed on the '(\w+)' tag/)
        if (match) {
          const field = match[1].replace(/([A-Z])/g, ' $1').trim() // Convert camelCase to spaces
          const rule = match[2]
          
          if (rule === 'min') {
            errorMessage = `${field} is too short`
          } else if (rule === 'required') {
            errorMessage = `${field} is required`
          } else if (rule === 'email') {
            errorMessage = `Please enter a valid email address`
          } else {
            errorMessage = `${field} validation failed`
          }
        } else {
          errorMessage = data.error
        }
      }
      
      toast.error('Failed to Create Shop', {
        description: errorMessage
      })
      return
    }

    // Show success dialog with credentials
    showSuccessDialog.value = true
  } catch (e: any) {
    toast.error('Failed to Create Shop', {
      description: e.message || 'An unexpected error occurred'
    })
  } finally {
    isLoading.value = false
  }
}

const goBack = () => {
  router.push('/dashboard/admin/dashboard')
}

// Check if current step can proceed
const canProceed = computed(() => {
  if (currentStep.value === 1) {
    return name.value.trim().length >= 3
  }
  return true
})
</script>

<template>
  <div class="flex min-h-screen flex-col bg-muted/40 p-6">
    <div class="mx-auto w-full max-w-3xl space-y-6">
      <!-- Back Button -->
      <Button variant="ghost" @click="goBack" class="w-fit">
        <ArrowLeft class="mr-2 h-4 w-4" />
        Back to Dashboard
      </Button>

      <!-- Progress Steps -->
      <div class="flex justify-between items-center px-2">
        <div v-for="step in totalSteps" :key="step" class="flex items-center">
          <div 
            class="flex items-center justify-center w-8 h-8 rounded-full border-2 text-sm font-bold transition-colors"
            :class="[
              step <= currentStep ? 'border-primary bg-primary text-primary-foreground' : 'border-muted-foreground text-muted-foreground'
            ]"
          >
            <Check v-if="step < currentStep" class="h-4 w-4" />
            <span v-else>{{ step }}</span>
          </div>
          <div 
            v-if="step < totalSteps" 
            class="w-24 h-0.5 mx-2 transition-colors"
            :class="step < currentStep ? 'bg-primary' : 'bg-muted'"
          ></div>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle class="text-2xl">
            <span v-if="currentStep === 1">Step 1: Shop Identity</span>
            <span v-else-if="currentStep === 2">Step 2: Billing & Plan</span>
            <span v-else>Step 3: Configuration & Review</span>
          </CardTitle>
          <CardDescription>
            <span v-if="currentStep === 1">Let's start with the basics of your new car rental business.</span>
            <span v-else-if="currentStep === 2">Choose a subscription plan and payment method.</span>
            <span v-else>Finalize the technical details and create your shop.</span>
          </CardDescription>
        </CardHeader>
        
        <CardContent>
          <form @submit.prevent="handleCreateTenant">
            
            <!-- STEP 1: Identity -->
            <div v-if="currentStep === 1" class="grid gap-6">
              <!-- Shop Logo Upload -->
              <div class="grid gap-2">
                <Label>Shop Logo (Optional)</Label>
                <div class="flex items-start gap-4">
                  <div class="flex-1">
                    <div class="border-2 border-dashed rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer relative bg-muted/20">
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
                        <img :src="logoPreview" alt="Logo preview" class="mx-auto h-24 w-24 object-contain rounded-md shadow-sm" />
                        <p class="text-xs text-muted-foreground">Click to change</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Shop Name -->
              <div class="grid gap-2">
                <Label for="name" :class="errors.name ? 'text-destructive' : ''">Shop Name *</Label>
                <div class="relative">
                  <Input 
                    id="name" 
                    v-model="name" 
                    placeholder="e.g. Avis Car Rental" 
                    required 
                    class="text-lg pr-10"
                    :class="errors.name ? 'border-destructive focus-visible:ring-destructive' : ''"
                    @blur="validateName"
                  />
                  <AlertCircle v-if="errors.name" class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-destructive" />
                </div>
                <p v-if="errors.name" class="text-sm text-destructive flex items-center gap-1">
                  {{ errors.name }}
                </p>
              </div>
            </div>

            <!-- STEP 2: Billing -->
            <div v-else-if="currentStep === 2" class="grid gap-8">
              
              <!-- Subscription Tier -->
              <div class="grid gap-4">
                <Label class="text-base">Select Subscription Plan</Label>
                <RadioGroup v-model="subscriptionTier" class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  
                  <!-- Normal Plan -->
                  <div>
                    <RadioGroupItem value="normal" id="tier-normal" class="peer sr-only" />
                    <Label
                      for="tier-normal"
                      class="flex flex-col items-center justify-between rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer h-full"
                    >
                      <Store class="mb-3 h-6 w-6" />
                      <div class="text-center space-y-1">
                        <div class="font-semibold">Normal</div>
                        <div class="text-sm text-muted-foreground">Up to 10 Cars</div>
                        <div class="text-xs text-muted-foreground">1 Staff Member</div>
                      </div>
                    </Label>
                  </div>

                  <!-- Pro Plan -->
                  <div>
                    <RadioGroupItem value="pro" id="tier-pro" class="peer sr-only" />
                    <Label
                      for="tier-pro"
                      class="flex flex-col items-center justify-between rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer h-full"
                    >
                      <ShieldCheck class="mb-3 h-6 w-6" />
                      <div class="text-center space-y-1">
                        <div class="font-semibold">Pro</div>
                        <div class="text-sm text-muted-foreground">Up to 50 Cars</div>
                        <div class="text-xs text-muted-foreground">5 Staff Members</div>
                      </div>
                    </Label>
                  </div>

                  <!-- Premium Plan -->
                  <div>
                    <RadioGroupItem value="premium" id="tier-premium" class="peer sr-only" />
                    <Label
                      for="tier-premium"
                      class="flex flex-col items-center justify-between rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer h-full"
                    >
                      <div class="mb-3 h-6 w-6 flex items-center justify-center font-bold text-lg">👑</div>
                      <div class="text-center space-y-1">
                        <div class="font-semibold">Premium</div>
                        <div class="text-sm text-muted-foreground">Unlimited Cars</div>
                        <div class="text-xs text-muted-foreground">Unlimited Staff</div>
                      </div>
                    </Label>
                  </div>
                </RadioGroup>
              </div>

              <!-- Payment Method -->
              <div class="grid gap-4">
                <Label class="text-base">Payment Method</Label>
                <RadioGroup v-model="paymentMethod" class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  
                  <div>
                    <RadioGroupItem value="online" id="pay-online" class="peer sr-only" />
                    <Label
                      for="pay-online"
                      class="flex items-center gap-4 rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer"
                    >
                      <CreditCard class="h-5 w-5" />
                      <div class="space-y-1">
                        <div class="font-semibold">Online Payment</div>
                        <div class="text-xs text-muted-foreground">Credit Card / Stripe</div>
                      </div>
                    </Label>
                  </div>

                  <div>
                    <RadioGroupItem value="cash" id="pay-cash" class="peer sr-only" />
                    <Label
                      for="pay-cash"
                      class="flex items-center gap-4 rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer"
                    >
                      <Banknote class="h-5 w-5" />
                      <div class="space-y-1">
                        <div class="font-semibold">Cash / Manual</div>
                        <div class="text-xs text-muted-foreground">Pay in person or bank transfer</div>
                      </div>
                    </Label>
                  </div>

                </RadioGroup>
              </div>

            </div>

            <!-- STEP 3: Configuration -->
            <div v-else class="grid gap-6">
              
              <div class="bg-muted/30 p-4 rounded-lg space-y-2 border">
                <h4 class="font-semibold text-sm text-muted-foreground uppercase tracking-wide">Review Summary</h4>
                <div class="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span class="text-muted-foreground">Shop Name:</span>
                    <p class="font-medium">{{ name }}</p>
                  </div>
                  <div>
                    <span class="text-muted-foreground">Plan:</span>
                    <p class="font-medium capitalize">{{ subscriptionTier }} ({{ paymentMethod }})</p>
                  </div>
                </div>
              </div>

              <!-- Subdomain -->
              <div class="grid gap-2">
                <Label for="subdomain" :class="errors.subdomain ? 'text-destructive' : ''">Subdomain *</Label>
                <div class="flex items-center gap-2">
                  <div class="relative flex-1">
                    <Input 
                      id="subdomain" 
                      v-model="subdomain" 
                      placeholder="avis" 
                      required 
                      :disabled="isLoading"
                      :class="errors.subdomain ? 'border-destructive focus-visible:ring-destructive pr-10' : ''"
                      @blur="validateSubdomain"
                    />
                    <AlertCircle v-if="errors.subdomain" class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-destructive" />
                  </div>
                  <span class="text-sm text-muted-foreground whitespace-nowrap">{{ config.frontendUrl.replace('http://', '.').replace('https://', '.') }}</span>
                </div>
                <p v-if="errors.subdomain" class="text-sm text-destructive">
                  {{ errors.subdomain }}
                </p>
                <p v-else class="text-xs text-muted-foreground">This will be your unique address for the admin portal.</p>
              </div>
              
              <!-- Admin Email -->
              <div class="grid gap-2">
                <Label for="adminEmail" :class="errors.adminEmail ? 'text-destructive' : ''">Admin Email *</Label>
                <div class="relative">
                  <Input 
                    id="adminEmail" 
                    v-model="adminEmail" 
                    type="email" 
                    placeholder="admin@avis.com" 
                    required 
                    :disabled="isLoading"
                    class="pr-10"
                    :class="errors.adminEmail ? 'border-destructive focus-visible:ring-destructive' : ''"
                    @blur="validateEmail"
                  />
                  <AlertCircle v-if="errors.adminEmail" class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-destructive" />
                </div>
                <p v-if="errors.adminEmail" class="text-sm text-destructive">
                  {{ errors.adminEmail }}
                </p>
              </div>

              <!-- Admin Password -->
              <div class="grid gap-2">
                <Label for="adminPassword" :class="errors.adminPassword ? 'text-destructive' : ''">Admin Password *</Label>
                <div class="relative">
                  <Input 
                    id="adminPassword" 
                    v-model="adminPassword" 
                    type="password" 
                    required 
                    :disabled="isLoading"
                    placeholder="Min. 8 chars, 1 uppercase, 1 lowercase, 1 number"
                    class="pr-10"
                    :class="errors.adminPassword ? 'border-destructive focus-visible:ring-destructive' : ''"
                    @blur="validatePassword"
                  />
                  <AlertCircle v-if="errors.adminPassword" class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-destructive" />
                </div>
                <p v-if="errors.adminPassword" class="text-sm text-destructive">
                  {{ errors.adminPassword }}
                </p>
                <p v-else class="text-xs text-muted-foreground">Must include uppercase, lowercase, and number</p>
              </div>

            </div>

          </form>
        </CardContent>
        
        <CardFooter class="flex justify-between">
          <Button 
            variant="outline" 
            @click="prevStep" 
            :disabled="currentStep === 1 || isLoading"
          >
            Previous
          </Button>

          <Button 
            v-if="currentStep < totalSteps" 
            @click="nextStep"
            :disabled="!canProceed"
          >
            Next Step
          </Button>
          
          <Button 
            v-else 
            @click="handleCreateTenant" 
            :disabled="isLoading"
          >
            <span v-if="isLoading">Creating Shop...</span>
            <span v-else>Confirm & Create</span>
          </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Success Dialog with Credentials -->
    <TenantCreatedSuccess
      v-model:open="showSuccessDialog"
      :shop-name="name"
      :subdomain="subdomain"
      :admin-email="adminEmail"
      :admin-password="adminPassword"
      :subscription-tier="subscriptionTier"
      :payment-method="paymentMethod"
      @continue="router.push('/dashboard/admin/dashboard')"
    />
  </div>
</template>
