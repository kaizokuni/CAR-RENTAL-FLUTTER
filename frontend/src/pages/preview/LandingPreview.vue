<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useBrandingStore } from '@/stores/branding'
import { Phone, Mail, MapPin, Car, Shield, Clock, Award, Facebook, Instagram } from 'lucide-vue-next'

const authStore = useAuthStore()
const brandingStore = useBrandingStore()

interface LandingPageSettings {
  hero_title: string
  hero_subtitle: string
  hero_cta_text: string
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

const settings = ref<LandingPageSettings | null>(null)
const isLoading = ref(true)
const isOffline = ref(false)

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
      settings.value = data
      if (!data.is_live) {
        isOffline.value = true
      }
    }
  } catch (e) {
    console.error('Failed to fetch landing page settings:', e)
  } finally {
    isLoading.value = false
  }
}

const tenantName = computed(() => authStore.user?.tenant_name || 'Car Rental')
const logoUrl = computed(() => brandingStore.branding.logo_url)

const openWhatsApp = () => {
  if (settings.value?.whatsapp_number) {
    const number = settings.value.whatsapp_number.replace(/[^\d]/g, '')
    window.open(`https://wa.me/${number}`, '_blank')
  }
}

onMounted(async () => {
  await brandingStore.fetchBranding()
  await fetchSettings()
})
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- Loading -->
    <div v-if="isLoading" class="min-h-screen flex items-center justify-center">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>

    <!-- Maintenance Mode -->
    <div v-else-if="isOffline" class="min-h-screen flex flex-col items-center justify-center p-6">
      <div class="text-center max-w-md">
        <div class="mb-6">
          <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-20 mx-auto" />
        </div>
        <h1 class="text-3xl font-bold mb-4">We'll Be Right Back</h1>
        <p class="text-muted-foreground mb-6">
          Our website is currently under maintenance. Please check back soon!
        </p>
        <div class="flex gap-4 justify-center">
          <a v-if="settings?.contact_phone" :href="'tel:' + settings.contact_phone" 
             class="flex items-center gap-2 text-primary hover:underline">
            <Phone class="h-4 w-4" />
            {{ settings.contact_phone }}
          </a>
        </div>
      </div>
    </div>

    <!-- Live Landing Page -->
    <div v-else-if="settings" class="relative">
      <!-- WhatsApp Floating Button -->
      <button 
        v-if="settings.whatsapp_number"
        @click="openWhatsApp"
        class="fixed bottom-6 right-6 z-50 bg-green-500 hover:bg-green-600 text-white rounded-full p-4 shadow-lg transition-transform hover:scale-110"
        title="Chat on WhatsApp"
      >
        <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
          <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
        </svg>
      </button>

      <!-- Hero Section -->
      <section class="relative min-h-[70vh] flex items-center justify-center bg-gradient-to-br from-primary/20 to-secondary/20">
        <div class="absolute inset-0 bg-black/20"></div>
        <div class="relative z-10 text-center px-6 max-w-4xl">
          <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-16 mx-auto mb-6" />
          <h1 class="text-4xl md:text-6xl font-bold mb-4">{{ settings.hero_title }}</h1>
          <p class="text-xl md:text-2xl text-muted-foreground mb-8">{{ settings.hero_subtitle }}</p>
          <button class="bg-primary text-primary-foreground px-8 py-4 rounded-lg text-lg font-semibold hover:opacity-90 transition">
            {{ settings.hero_cta_text }}
          </button>
        </div>
      </section>

      <!-- Features Section -->
      <section v-if="settings.show_features" class="py-20 px-6 bg-muted/30">
        <div class="max-w-6xl mx-auto">
          <h2 class="text-3xl font-bold text-center mb-12">Why Choose Us?</h2>
          <div class="grid md:grid-cols-3 gap-8">
            <div class="bg-card p-6 rounded-xl shadow-sm text-center">
              <Car class="h-12 w-12 mx-auto mb-4 text-primary" />
              <h3 class="text-xl font-semibold mb-2">Wide Selection</h3>
              <p class="text-muted-foreground">Choose from our diverse fleet of vehicles</p>
            </div>
            <div class="bg-card p-6 rounded-xl shadow-sm text-center">
              <Shield class="h-12 w-12 mx-auto mb-4 text-primary" />
              <h3 class="text-xl font-semibold mb-2">Fully Insured</h3>
              <p class="text-muted-foreground">All vehicles come with comprehensive insurance</p>
            </div>
            <div class="bg-card p-6 rounded-xl shadow-sm text-center">
              <Clock class="h-12 w-12 mx-auto mb-4 text-primary" />
              <h3 class="text-xl font-semibold mb-2">24/7 Support</h3>
              <p class="text-muted-foreground">Round-the-clock customer assistance</p>
            </div>
          </div>
        </div>
      </section>

      <!-- About Section -->
      <section v-if="settings.show_about && settings.about_text" class="py-20 px-6">
        <div class="max-w-4xl mx-auto text-center">
          <h2 class="text-3xl font-bold mb-8">About Us</h2>
          <p class="text-lg text-muted-foreground whitespace-pre-line">{{ settings.about_text }}</p>
        </div>
      </section>

      <!-- Contact Section -->
      <section class="py-20 px-6 bg-muted/30">
        <div class="max-w-4xl mx-auto">
          <h2 class="text-3xl font-bold text-center mb-12">Contact Us</h2>
          <div class="grid md:grid-cols-3 gap-8 text-center">
            <div v-if="settings.contact_phone">
              <Phone class="h-8 w-8 mx-auto mb-3 text-primary" />
              <p class="font-medium">Phone</p>
              <a :href="'tel:' + settings.contact_phone" class="text-muted-foreground hover:text-primary">
                {{ settings.contact_phone }}
              </a>
            </div>
            <div v-if="settings.contact_email">
              <Mail class="h-8 w-8 mx-auto mb-3 text-primary" />
              <p class="font-medium">Email</p>
              <a :href="'mailto:' + settings.contact_email" class="text-muted-foreground hover:text-primary">
                {{ settings.contact_email }}
              </a>
            </div>
            <div v-if="settings.contact_address">
              <MapPin class="h-8 w-8 mx-auto mb-3 text-primary" />
              <p class="font-medium">Address</p>
              <p class="text-muted-foreground">{{ settings.contact_address }}</p>
            </div>
          </div>
          <!-- Social Links -->
          <div v-if="settings.social_facebook || settings.social_instagram || settings.social_tiktok" 
               class="flex justify-center gap-6 mt-12">
            <a v-if="settings.social_facebook" :href="settings.social_facebook" target="_blank" 
               class="text-muted-foreground hover:text-primary transition">
              <Facebook class="h-6 w-6" />
            </a>
            <a v-if="settings.social_instagram" :href="settings.social_instagram" target="_blank"
               class="text-muted-foreground hover:text-primary transition">
              <Instagram class="h-6 w-6" />
            </a>
            <a v-if="settings.social_tiktok" :href="settings.social_tiktok" target="_blank"
               class="text-muted-foreground hover:text-primary transition">
              <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z"/>
              </svg>
            </a>
          </div>
        </div>
      </section>

      <!-- Footer -->
      <footer class="py-8 px-6 border-t">
        <div class="max-w-6xl mx-auto text-center text-muted-foreground">
          <p>© {{ new Date().getFullYear() }} {{ tenantName }}. All rights reserved.</p>
        </div>
      </footer>
    </div>
  </div>
</template>
