<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { usePermissions } from '@/composables/usePermissions'
import { useAuthStore } from '@/stores/auth'
import { useCarsStore } from '@/stores/cars'
import { useBrandingStore } from '@/stores/branding'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import SPhoneInput from '@/components/common/SPhoneInput.vue'
import { 
  Palette, Globe, Car, Rocket, ChevronLeft, ChevronRight, Check, Upload, 
  Phone, Mail, MapPin, MessageCircle, Copy, Eye, Power, GripVertical 
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const router = useRouter()
const { canAccess } = usePermissions()
const authStore = useAuthStore()
const carsStore = useCarsStore()
const brandingStore = useBrandingStore()

// Current step
const currentStep = ref(1)
const steps = [
  { id: 1, name: 'Branding', icon: Palette },
  { id: 2, name: 'Content', icon: Globe },
  { id: 3, name: 'Cars', icon: Car }
]

// Branding state
const branding = ref({
  logo_url: '',
  primary_color: '#3b82f6',
  secondary_color: '#10b981'
})
const extractedColors = ref<string[]>([])
const logoFile = ref<File | null>(null)
const logoPreview = ref('')

// Landing page state
const settings = ref({
  hero_title: 'Welcome to Our Car Rental',
  hero_subtitle: 'Find the perfect car for your journey',
  hero_cta_text: 'Browse Cars',
  show_features: true,
  show_fleet: true,
  show_about: true,
  about_text: '',
  contact_phone: '',
  contact_email: '',
  contact_address: '',
  whatsapp_number: '',
  social_facebook: '',
  social_instagram: '',
  social_tiktok: '',
  is_live: false,
  selected_cars: [] as string[]
})

const isLoading = ref(true)
const isSaving = ref(false)

const getAuthHeaders = () => ({
  'Authorization': `Bearer ${authStore.token}`,
  'Content-Type': 'application/json'
})

// Fetch all data
const fetchData = async () => {
  isLoading.value = true
  try {
    console.log('Marketing: Fetching data...')
    
    // Fetch branding
    const brandingRes = await fetch('/api/v1/branding', { headers: getAuthHeaders() })
    console.log('Branding response:', brandingRes.status)
    if (brandingRes.ok) {
      const data = await brandingRes.json()
      console.log('Branding data:', data)
      branding.value = { 
        logo_url: data.logo_url || '',
        primary_color: data.primary_color || '#3b82f6',
        secondary_color: data.secondary_color || '#10b981'
      }
      if (data.logo_url) logoPreview.value = data.logo_url
    }

    // Fetch landing page
    const landingRes = await fetch('/api/v1/landing-page', { headers: getAuthHeaders() })
    console.log('Landing response:', landingRes.status)
    if (landingRes.ok) {
      const data = await landingRes.json()
      console.log('Landing data:', data)
      settings.value = {
        hero_title: data.hero_title || 'Welcome to Our Car Rental',
        hero_subtitle: data.hero_subtitle || 'Find the perfect car for your journey',
        hero_cta_text: data.hero_cta_text || 'Browse Cars',
        show_features: data.show_features ?? true,
        show_fleet: data.show_fleet ?? true,
        show_about: data.show_about ?? true,
        about_text: data.about_text || '',
        contact_phone: data.contact_phone || '',
        contact_email: data.contact_email || '',
        contact_address: data.contact_address || '',
        whatsapp_number: data.whatsapp_number || '',
        social_facebook: data.social_facebook || '',
        social_instagram: data.social_instagram || '',
        social_tiktok: data.social_tiktok || '',
        is_live: data.is_live ?? false,
        selected_cars: data.selected_cars || []
      }
    }

    // Fetch cars
    await carsStore.fetchCars()
    console.log('Cars loaded:', carsStore.cars.length)
  } catch (e) {
    console.error('Failed to fetch data:', e)
    toast.error('Failed to load marketing data')
  } finally {
    isLoading.value = false
  }
}

// Logo upload
const handleLogoUpload = async (e: Event) => {
  const input = e.target as HTMLInputElement
  if (!input.files || !input.files[0]) return

  const file = input.files[0]
  logoFile.value = file

  // Preview
  const reader = new FileReader()
  reader.onload = (event) => {
    if (event.target?.result) {
      logoPreview.value = event.target.result as string
      extractColors(event.target.result as string)
    }
  }
  reader.readAsDataURL(file)

  // Upload
  const formData = new FormData()
  formData.append('logo', file)
  try {
    const res = await fetch('/api/v1/branding/logo', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${authStore.token}` },
      body: formData
    })
    if (res.ok) {
      const data = await res.json()
      branding.value.logo_url = data.logo_url
      toast.success('Logo uploaded!')
    }
  } catch (e) {
    toast.error('Failed to upload logo')
  }
}

// Extract colors from image (simple version - max 3)
const extractColors = (dataUrl: string) => {
  const img = new Image()
  img.onload = () => {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    
    canvas.width = 50
    canvas.height = 50
    ctx.drawImage(img, 0, 0, 50, 50)
    
    const imageData = ctx.getImageData(0, 0, 50, 50)
    const colors: { [key: string]: number } = {}
    
    for (let i = 0; i < imageData.data.length; i += 4) {
      const r = imageData.data[i] ?? 0
      const g = imageData.data[i + 1] ?? 0
      const b = imageData.data[i + 2] ?? 0
      // Skip white/black
      if ((r > 240 && g > 240 && b > 240) || (r < 15 && g < 15 && b < 15)) continue
      const hex = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
      colors[hex] = (colors[hex] || 0) + 1
    }
    
    // Get top 3 colors
    extractedColors.value = Object.entries(colors)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([color]) => color)
  }
  img.src = dataUrl
}

const selectColor = (color: string, isPrimary: boolean) => {
  if (isPrimary) branding.value.primary_color = color
  else branding.value.secondary_color = color
}

// Save branding
const saveBranding = async () => {
  try {
    await fetch('/api/v1/branding', {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(branding.value)
    })
    toast.success('Branding saved!')
  } catch (e) {
    toast.error('Failed to save branding')
  }
}

// Save landing page
const saveLanding = async () => {
  isSaving.value = true
  try {
    await brandingStore.updateLandingPage(settings.value)
    toast.success('Changes saved!')
  } catch (e) {
    toast.error('Failed to save')
  } finally {
    isSaving.value = false
  }
}

const isTogglingLive = ref(false)

const toggleLive = async (val: boolean) => {
  if (isTogglingLive.value) return
  
  isTogglingLive.value = true
  const previous = settings.value.is_live
  settings.value.is_live = val // Optimistic update
  
  try {
    await brandingStore.updateLandingPage(settings.value)
    toast.success(val ? 'Site is now LIVE' : 'Site is now Offline')
    // No need to call saveLanding() again if we called store directly
  } catch (e) {
    settings.value.is_live = previous // Revert
    toast.error('Failed to update status')
  } finally {
    isTogglingLive.value = false
  }
}

// Cars selection
const toggleCar = (carId: string) => {
  const idx = settings.value.selected_cars.indexOf(carId)
  if (idx === -1) {
    settings.value.selected_cars.push(carId)
  } else {
    settings.value.selected_cars.splice(idx, 1)
  }
}

const isCarSelected = (carId: string) => settings.value.selected_cars.includes(carId)

const moveCar = (index: number, direction: 'up' | 'down') => {
  const arr = settings.value.selected_cars
  if (direction === 'up' && index > 0) {
    const temp = arr[index] as string
    arr[index] = arr[index - 1] as string
    arr[index - 1] = temp
  } else if (direction === 'down' && index < arr.length - 1) {
    const temp = arr[index] as string
    arr[index] = arr[index + 1] as string
    arr[index + 1] = temp
  }
}

const selectedCarsDetails = computed(() => {
  return settings.value.selected_cars
    .map(id => carsStore.cars.find(c => c.id === id))
    .filter(Boolean)
})



const previewUrl = computed(() => {
  const subdomain = authStore.tenantSubdomain || 'default'
  const protocol = window.location.protocol
  const port = window.location.port ? `:${window.location.port}` : ''
  const hostname = window.location.hostname

  // Handle localhost
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return `${protocol}//${subdomain}.localhost${port}`
  }

  // Handle production/other (replace first part of domain or append)
  // Simple assumption: replace 'app' or 'www' or prepend
  const parts = hostname.split('.')
  if (parts.length > 2) {
    // e.g. app.domain.com -> tenant.domain.com
    parts[0] = subdomain
    return `${protocol}//${parts.join('.')}${port}`
  }
  
  return `${protocol}//${subdomain}.${hostname}${port}`
})

const copyLink = async () => {
  await navigator.clipboard.writeText(previewUrl.value)
  toast.success('Link copied to clipboard!')
}


const openPreview = () => {
  const routeData = router.resolve({ name: 'landing-preview' })
  window.open(routeData.href, '_blank')
}

// Navigation - save on each step
const nextStep = async () => {
  isSaving.value = true
  try {
    // Always save current step
    if (currentStep.value === 1) {
      await saveBranding()
    } else {
      await saveLanding()
    }
    // Move to next step
    if (currentStep.value < 3) currentStep.value++
  } finally {
    isSaving.value = false
  }
}

const prevStep = async () => {
  // Save before going back too
  isSaving.value = true
  try {
    if (currentStep.value === 1) {
      await saveBranding()
    } else {
      await saveLanding()
    }
  } finally {
    isSaving.value = false
  }
  if (currentStep.value > 1) currentStep.value--
}

onMounted(fetchData)
</script>

<template>
  <div v-if="!canAccess(undefined, 'premium')" class="h-full">
    <UpgradeRequired 
      title="Marketing Hub" 
      description="Build your brand, customize your landing page, and attract more customers."
      required-plan="Premium"
    />
  </div>
  
  <div v-else class="p-6">
    <!-- Header -->
      <div class="sticky top-0 z-40 bg-background/95 backdrop-blur -mx-6 px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4 border-b shadow-sm">
        <div>
           <h2 class="text-2xl font-bold tracking-tight">Marketing</h2>
           <p class="text-muted-foreground">Manage your public presence</p>
        </div>
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 px-3 py-1.5 bg-muted rounded-full border">
            <span class="text-sm font-medium" :class="settings.is_live ? 'text-green-600' : 'text-muted-foreground'">
               {{ settings.is_live ? 'Live' : 'Offline' }}
            </span>
            <Switch :checked="settings.is_live" @update:checked="toggleLive" />
          </div>
          <Button variant="outline" size="sm" @click="openPreview">
            <Eye class="mr-2 h-4 w-4" />
            Preview
          </Button>
          <Button variant="outline" size="sm" @click="copyLink">
            <Copy class="mr-2 h-4 w-4" />
            Copy Link
          </Button>
        </div>
      </div>

      <!-- Detail Steps -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8 mt-6">
        <div 
          v-for="step in steps" 
          :key="step.id"
          class="flex items-center p-4 bg-card rounded-lg border cursor-pointer transition-all hover:bg-muted/50"
          :class="{
            'border-primary ring-1 ring-primary': currentStep === step.id,
            'opacity-50': currentStep !== step.id
          }"
          @click="currentStep = step.id"
        >
          <div class="p-2 rounded-full bg-primary/10 mr-4">
            <component :is="step.icon" class="h-5 w-5 text-primary" />
          </div>
          <div>
            <h3 class="font-medium">{{ step.name }}</h3>
            <p class="text-xs text-muted-foreground">
              {{ step.id === currentStep ? 'Editing now' : 'Click to edit' }}
            </p>
          </div>
        </div>
      </div>

    <div v-if="isLoading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>

    <div v-else class="max-w-4xl mx-auto">
      <!-- Step 1: Branding -->
      <div v-show="currentStep === 1" class="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Upload class="h-5 w-5" />
              Logo Upload
            </CardTitle>
            <CardDescription>Upload your company logo</CardDescription>
          </CardHeader>
          <CardContent>
            <div class="flex items-center gap-6">
              <div class="w-32 h-32 border-2 border-dashed rounded-lg flex items-center justify-center bg-muted/50 overflow-hidden">
                <img v-if="logoPreview" :src="logoPreview" alt="Logo" class="max-w-full max-h-full object-contain" />
                <Upload v-else class="h-8 w-8 text-muted-foreground" />
              </div>
              <div>
                <input type="file" id="logo-upload" accept="image/*" class="hidden" @change="handleLogoUpload" />
                <label for="logo-upload">
                  <Button as="span" variant="outline" class="cursor-pointer">
                    <Upload class="mr-2 h-4 w-4" />
                    Choose Logo
                  </Button>
                </label>
                <p class="text-sm text-muted-foreground mt-2">PNG, JPG or SVG. Max 2MB.</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Palette class="h-5 w-5" />
              Brand Colors
            </CardTitle>
            <CardDescription>Choose your primary and secondary colors</CardDescription>
          </CardHeader>
          <CardContent class="space-y-6">
            <!-- Extracted colors -->
            <div v-if="extractedColors.length > 0" class="space-y-3">
              <Label>Suggested from your logo (click to use):</Label>
              <div class="flex gap-3">
                <button
                  v-for="color in extractedColors"
                  :key="color"
                  class="w-12 h-12 rounded-lg border-2 transition-transform hover:scale-110"
                  :style="{ backgroundColor: color }"
                  @click="selectColor(color, true)"
                  :title="color"
                />
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <Label>Primary Color</Label>
                <div class="flex items-center gap-3">
                  <input 
                    type="color" 
                    v-model="branding.primary_color"
                    class="w-12 h-12 rounded cursor-pointer"
                  />
                  <Input v-model="branding.primary_color" class="flex-1" />
                </div>
              </div>
              <div class="space-y-2">
                <Label>Secondary Color</Label>
                <div class="flex items-center gap-3">
                  <input 
                    type="color" 
                    v-model="branding.secondary_color"
                    class="w-12 h-12 rounded cursor-pointer"
                  />
                  <Input v-model="branding.secondary_color" class="flex-1" />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Step 2: Content -->
      <div v-show="currentStep === 2" class="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Hero Section</CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div class="space-y-2">
              <Label>Title</Label>
              <Input v-model="settings.hero_title" placeholder="Welcome to Our Car Rental" />
            </div>
            <div class="space-y-2">
              <Label>Subtitle</Label>
              <Input v-model="settings.hero_subtitle" placeholder="Find the perfect car for your journey" />
            </div>
            <div class="space-y-2">
              <Label>Button Text</Label>
              <Input v-model="settings.hero_cta_text" placeholder="Browse Cars" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>About</CardTitle>
          </CardHeader>
          <CardContent>
            <textarea 
              v-model="settings.about_text" 
              placeholder="Tell customers about your business..."
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
            ></textarea>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Contact & Social</CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div class="grid md:grid-cols-2 gap-4">
              <div class="space-y-2">
                <Label><Phone class="inline h-4 w-4 mr-1" />Phone</Label>
                <SPhoneInput v-model="settings.contact_phone" default-country="MA" />
              </div>
              <div class="space-y-2">
                <Label><Mail class="inline h-4 w-4 mr-1" />Email</Label>
                <Input v-model="settings.contact_email" placeholder="contact@company.com" />
              </div>
            </div>
            <div class="space-y-2">
              <Label><MapPin class="inline h-4 w-4 mr-1" />Address</Label>
              <Input v-model="settings.contact_address" placeholder="Your address" />
            </div>
            <div class="space-y-2">
              <Label class="text-green-600"><MessageCircle class="inline h-4 w-4 mr-1" />WhatsApp</Label>
              <SPhoneInput v-model="settings.whatsapp_number" default-country="MA" />
            </div>
            <div class="grid md:grid-cols-3 gap-4">
              <div class="space-y-2">
                <Label>Facebook</Label>
                <Input v-model="settings.social_facebook" placeholder="https://facebook.com/..." />
              </div>
              <div class="space-y-2">
                <Label>Instagram</Label>
                <Input v-model="settings.social_instagram" placeholder="https://instagram.com/..." />
              </div>
              <div class="space-y-2">
                <Label>TikTok</Label>
                <Input v-model="settings.social_tiktok" placeholder="https://tiktok.com/@..." />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Step 3: Cars -->
      <div v-show="currentStep === 3" class="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Select Cars to Display</CardTitle>
            <CardDescription>Choose which cars appear on your landing page</CardDescription>
          </CardHeader>
          <CardContent>
            <div class="grid md:grid-cols-2 gap-4 max-h-[400px] overflow-auto">
              <div
                v-for="car in carsStore.cars"
                :key="car.id"
                class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                :class="isCarSelected(car.id) ? 'border-primary bg-primary/5' : 'hover:bg-muted/50'"
                @click="toggleCar(car.id)"
              >
                <div :class="['w-5 h-5 rounded border-2 flex items-center justify-center', isCarSelected(car.id) ? 'bg-primary border-primary' : 'border-muted-foreground']">
                  <Check v-if="isCarSelected(car.id)" class="h-3 w-3 text-primary-foreground" />
                </div>
                <img 
                  v-if="car.image_url" 
                  :src="car.image_url" 
                  :alt="car.brand"
                  class="w-16 h-12 object-cover rounded"
                />
                <div class="flex-1">
                  <p class="font-medium">{{ car.brand }} {{ car.model }}</p>
                  <p class="text-sm text-muted-foreground">{{ car.year }} • {{ car.price_per_day }} MAD/day</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card v-if="selectedCarsDetails.length > 0">
          <CardHeader>
            <CardTitle>Display Order</CardTitle>
            <CardDescription>Drag to reorder how cars appear</CardDescription>
          </CardHeader>
          <CardContent>
            <div class="space-y-2">
              <div
                v-for="(car, idx) in selectedCarsDetails"
                :key="car?.id"
                class="flex items-center gap-3 p-3 rounded-lg border bg-card"
              >
                <GripVertical class="h-5 w-5 text-muted-foreground cursor-grab" />
                <span class="w-6 h-6 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-sm">
                  {{ idx + 1 }}
                </span>
                <span class="flex-1 font-medium">{{ car?.brand }} {{ car?.model }}</span>
                <div class="flex gap-1">
                  <Button size="sm" variant="ghost" @click="moveCar(idx, 'up')" :disabled="idx === 0">↑</Button>
                  <Button size="sm" variant="ghost" @click="moveCar(idx, 'down')" :disabled="idx === selectedCarsDetails.length - 1">↓</Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Step 4: Publish -->
      <div v-show="currentStep === 4" class="space-y-6">
        <Card :class="settings.is_live ? 'border-green-500' : 'border-yellow-500'">
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Power class="h-5 w-5" />
              Landing Page Status
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div class="flex items-center justify-between">
              <div>
                <p class="font-medium text-lg">
                  {{ settings.is_live ? '🟢 LIVE' : '🟡 Maintenance Mode' }}
                </p>
                <p class="text-sm text-muted-foreground">
                  {{ settings.is_live ? 'Your landing page is visible to the public' : 'Visitors will see a maintenance message' }}
                </p>
              </div>
              <Button 
                :variant="settings.is_live ? 'destructive' : 'default'"
                @click="toggleLive(!settings.is_live)"
              >
                {{ settings.is_live ? 'Go Offline' : 'Go Live' }}
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Eye class="h-5 w-5" />
              Preview & Share
            </CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div class="flex items-center gap-3">
              <Input :model-value="previewUrl" readonly class="flex-1 bg-muted" />
              <Button variant="outline" @click="copyLink">
                <Copy class="mr-2 h-4 w-4" />
                Copy Link
              </Button>
            </div>
            <Button @click="openPreview" class="w-full">
              <Eye class="mr-2 h-4 w-4" />
              Open Preview
            </Button>
          </CardContent>
        </Card>
      </div>

      <!-- Navigation -->
      <div class="flex justify-between mt-8">
        <Button variant="outline" @click="prevStep" :disabled="currentStep === 1">
          <ChevronLeft class="mr-2 h-4 w-4" />
          Back
        </Button>
        <Button @click="nextStep" :disabled="isSaving">
          {{ currentStep === 4 ? 'Save' : 'Next' }}
          <ChevronRight v-if="currentStep < 4" class="ml-2 h-4 w-4" />
        </Button>
      </div>
    </div>
  </div>
</template>
