<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { usePermissions } from '@/composables/usePermissions'
import { useAuthStore } from '@/stores/auth'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import SPhoneInput from '@/components/common/SPhoneInput.vue'
import { Globe, Phone, Mail, MapPin, Save, Layout, Building2, Car, MessageCircle, Eye, Power } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const { canAccess } = usePermissions()
const authStore = useAuthStore()

interface LandingPageSettings {
  hero_title: string
  hero_subtitle: string
  hero_cta_text: string
  hero_background_url: string
  show_features: boolean
  show_fleet: boolean
  show_about: boolean
  about_text: string
  contact_phone: string
  contact_email: string
  contact_address: string
  whatsapp_number: string
  social_facebook: string
  social_instagram: string
  social_tiktok: string
  is_live: boolean
}

const settings = ref<LandingPageSettings>({
  hero_title: 'Welcome to Our Car Rental',
  hero_subtitle: 'Find the perfect car for your journey',
  hero_cta_text: 'Browse Cars',
  hero_background_url: '',
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
  is_live: false
})

const isLoading = ref(true)
const isSaving = ref(false)

const getAuthHeaders = () => ({
  'Authorization': `Bearer ${authStore.token}`,
  'Content-Type': 'application/json'
})

const fetchSettings = async () => {
  isLoading.value = true
  try {
    const response = await fetch('/api/v1/landing-page', {
      headers: getAuthHeaders()
    })
    if (response.ok) {
      const data = await response.json()
      settings.value = { ...settings.value, ...data }
    }
  } catch (e) {
    console.error('Failed to fetch landing page settings:', e)
  } finally {
    isLoading.value = false
  }
}

const saveSettings = async () => {
  isSaving.value = true
  try {
    const response = await fetch('/api/v1/landing-page', {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(settings.value)
    })
    if (!response.ok) throw new Error('Failed to save')
    toast.success('Landing page settings saved!')
  } catch (e) {
    toast.error('Failed to save settings')
  } finally {
    isSaving.value = false
  }
}

const toggleLive = async () => {
  settings.value.is_live = !settings.value.is_live
  await saveSettings()
  if (settings.value.is_live) {
    toast.success('Landing page is now LIVE!')
  } else {
    toast.info('Landing page is now in maintenance mode')
  }
}

const previewLandingPage = () => {
  // Open preview in new tab
  window.open('/preview/landing', '_blank')
}

const liveStatusText = computed(() => settings.value.is_live ? 'LIVE' : 'Maintenance')
const liveStatusClass = computed(() => settings.value.is_live 
  ? 'bg-green-500/20 text-green-500 border-green-500/50' 
  : 'bg-yellow-500/20 text-yellow-500 border-yellow-500/50'
)

onMounted(fetchSettings)
</script>

<template>
  <div v-if="!canAccess(undefined, 'premium')" class="h-full">
    <UpgradeRequired 
      title="Landing Page Builder" 
      description="Create a beautiful public landing page for your car rental business with customizable sections."
      required-plan="Premium"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-3xl font-bold tracking-tight flex items-center gap-2">
          <Globe class="h-8 w-8" />
          Landing Page Builder
        </h1>
        <p class="text-muted-foreground">Customize your public landing page for customers.</p>
      </div>
      <div class="flex items-center gap-3">
        <!-- Status Badge -->
        <span :class="['px-3 py-1 rounded-full text-sm font-medium border', liveStatusClass]">
          {{ liveStatusText }}
        </span>
        <!-- Preview Button -->
        <Button variant="outline" @click="previewLandingPage">
          <Eye class="mr-2 h-4 w-4" />
          Preview
        </Button>
        <!-- Toggle Live -->
        <Button 
          :variant="settings.is_live ? 'destructive' : 'default'"
          @click="toggleLive"
        >
          <Power class="mr-2 h-4 w-4" />
          {{ settings.is_live ? 'Go Offline' : 'Go Live' }}
        </Button>
        <!-- Save Button -->
        <Button @click="saveSettings" :disabled="isSaving">
          <Save class="mr-2 h-4 w-4" />
          {{ isSaving ? 'Saving...' : 'Save' }}
        </Button>
      </div>
    </div>

    <div v-if="isLoading" class="flex justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else class="grid gap-6 md:grid-cols-2">
      <!-- Hero Section -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Layout class="h-5 w-5" />
            Hero Section
          </CardTitle>
          <CardDescription>The main banner visitors see first</CardDescription>
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

      <!-- Section Visibility -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Building2 class="h-5 w-5" />
            Section Visibility
          </CardTitle>
          <CardDescription>Choose which sections to show</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="flex items-center justify-between">
            <div>
              <Label>Features Section</Label>
              <p class="text-sm text-muted-foreground">Key features of your service</p>
            </div>
            <Switch v-model:checked="settings.show_features" />
          </div>
          <div class="flex items-center justify-between">
            <div>
              <Label>Fleet Preview</Label>
              <p class="text-sm text-muted-foreground">Display available cars</p>
            </div>
            <Switch v-model:checked="settings.show_fleet" />
          </div>
          <div class="flex items-center justify-between">
            <div>
              <Label>About Section</Label>
              <p class="text-sm text-muted-foreground">About your business</p>
            </div>
            <Switch v-model:checked="settings.show_about" />
          </div>
        </CardContent>
      </Card>

      <!-- About -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Car class="h-5 w-5" />
            About Your Business
          </CardTitle>
          <CardDescription>Tell customers about your service</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="space-y-2">
            <Label>About Text</Label>
            <textarea 
              v-model="settings.about_text" 
              placeholder="Tell customers about your business..."
              class="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ></textarea>
          </div>
        </CardContent>
      </Card>

      <!-- Contact -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Phone class="h-5 w-5" />
            Contact Information
          </CardTitle>
          <CardDescription>How customers can reach you</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="space-y-2">
            <Label class="flex items-center gap-2">
              <Phone class="h-4 w-4" /> Phone Number
            </Label>
            <SPhoneInput v-model="settings.contact_phone" default-country="MA" />
          </div>
          <div class="space-y-2">
            <Label class="flex items-center gap-2">
              <Mail class="h-4 w-4" /> Email
            </Label>
            <Input v-model="settings.contact_email" placeholder="contact@yourcompany.com" />
          </div>
          <div class="space-y-2">
            <Label class="flex items-center gap-2">
              <MapPin class="h-4 w-4" /> Address
            </Label>
            <Input v-model="settings.contact_address" placeholder="Your business address" />
          </div>
        </CardContent>
      </Card>

      <!-- WhatsApp -->
      <Card class="border-green-500/50">
        <CardHeader>
          <CardTitle class="flex items-center gap-2 text-green-600">
            <MessageCircle class="h-5 w-5" />
            WhatsApp Floating Button
          </CardTitle>
          <CardDescription>Add a WhatsApp quick contact button on your landing page</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="space-y-2">
            <Label>WhatsApp Number</Label>
            <SPhoneInput v-model="settings.whatsapp_number" default-country="MA" />
            <p class="text-xs text-muted-foreground">
              This number will be used for the floating WhatsApp button on your landing page
            </p>
          </div>
        </CardContent>
      </Card>

      <!-- Social Links -->
      <Card>
        <CardHeader>
          <CardTitle>Social Media Links</CardTitle>
          <CardDescription>Connect your social profiles (Facebook, Instagram, TikTok)</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
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
        </CardContent>
      </Card>
    </div>
  </div>
</template>
