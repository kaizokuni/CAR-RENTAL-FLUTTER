<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { 
  Phone, Mail, MapPin, MessageCircle, Car, Users, Shield, Clock,
  ChevronRight, Facebook, Instagram
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const subdomain = computed(() => {
  if (route.params.subdomain) return route.params.subdomain as string
  
  const host = window.location.hostname
  if (host === 'localhost' || host === '127.0.0.1') return ''
  const parts = host.split('.')
  if (parts.length > 1 && parts[0] !== 'www') return parts[0]
  return ''
})

interface CarData {
  id: string
  brand: string
  model: string
  year: number
  daily_rate: number
  image_url: string
  images: string[]
  transmission: string
  fuel_type: string
  seats: number
}

interface LandingData {
  tenant_name: string
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
  branding: {
    logo_url: string
    primary_color: string
    secondary_color: string
  }
  cars: CarData[]
}

const data = ref<LandingData | null>(null)
const isLoading = ref(true)
const error = ref('')

const hexToHsl = (hex: string) => {
  let r = 0, g = 0, b = 0
  if (hex.length === 4) {
    r = parseInt("0x" + hex[1] + hex[1])
    g = parseInt("0x" + hex[2] + hex[2])
    b = parseInt("0x" + hex[3] + hex[3])
  } else if (hex.length === 7) {
    r = parseInt("0x" + hex[1] + hex[2])
    g = parseInt("0x" + hex[3] + hex[4])
    b = parseInt("0x" + hex[5] + hex[6])
  }
  r /= 255; g /= 255; b /= 255
  const cmin = Math.min(r,g,b), cmax = Math.max(r,g,b), delta = cmax - cmin
  let h = 0, s = 0, l = 0
  if (delta === 0) h = 0
  else if (cmax === r) h = ((g - b) / delta) % 6
  else if (cmax === g) h = (b - r) / delta + 2
  else h = (r - g) / delta + 4
  h = Math.round(h * 60)
  if (h < 0) h += 360
  l = (cmax + cmin) / 2
  s = delta === 0 ? 0 : delta / (1 - Math.abs(2 * l - 1))
  s = +(s * 100).toFixed(1)
  l = +(l * 100).toFixed(1)
  return `${h} ${s}% ${l}%`
}

const customStyles = computed(() => {
  if (!data.value?.branding) return {}
  return {
    '--primary': hexToHsl(data.value.branding.primary_color),
    '--secondary': hexToHsl(data.value.branding.secondary_color),
    '--primary-foreground': '210 40% 98%' // Keep text light
  } as any
})

const fetchData = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`/api/v1/public/landing/${subdomain.value}`)
    if (!res.ok) {
      error.value = 'Business not found'
      return
    }
    data.value = await res.json()
  } catch (e) {
    error.value = 'Failed to load page'
  } finally {
    isLoading.value = false
  }
}

const browseCars = () => {
  if (route.params.subdomain) {
    router.push(`/site/${subdomain.value}/cars`)
  } else {
    router.push('/cars')
  }
}

const searchQuery = ref('')
import { Search } from 'lucide-vue-next'

const handleSearch = () => {
  if (route.params.subdomain) {
    router.push({ 
      path: `/site/${subdomain.value}/cars`,
      query: { search: searchQuery.value }
    })
  } else {
    router.push({ 
      path: '/cars',
      query: { search: searchQuery.value }
    })
  }
}

const openWhatsApp = () => {
  if (data.value?.whatsapp_number) {
    // Remove non-digits for the link
    window.open(`https://wa.me/${data.value.whatsapp_number.replace(/\D/g, '')}`, '_blank')
  }
}

// Image Carousel Logic
const imgIndexes = ref<Record<string, number>>({})

const getCurrentImage = (car: any) => {
  const idx = imgIndexes.value[car.id] || 0
  if (car.images && car.images.length > 0) {
    return car.images[idx] || car.image_url
  }
  return car.image_url
}

const nextImage = (car: any) => {
  if (!car.images || car.images.length <= 1) return
  const current = imgIndexes.value[car.id] || 0
  imgIndexes.value[car.id] = (current + 1) % car.images.length
}

const prevImage = (car: any) => {
  if (!car.images || car.images.length <= 1) return
  const current = imgIndexes.value[car.id] || 0
  imgIndexes.value[car.id] = (current - 1 + car.images.length) % car.images.length
}

onMounted(fetchData)
</script>

<template>
  <div class="min-h-screen bg-background" :style="customStyles">
    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center min-h-screen">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <h1 class="text-4xl font-bold mb-4">404</h1>
        <p class="text-muted-foreground">{{ error }}</p>
      </div>
    </div>

    <!-- Maintenance Mode -->
    <div v-else-if="data && !data.is_live" class="flex items-center justify-center min-h-screen bg-gradient-to-br from-yellow-50 to-orange-50">
      <div class="text-center p-8">
        <div class="w-24 h-24 mx-auto mb-6 bg-yellow-100 rounded-full flex items-center justify-center">
          <Clock class="h-12 w-12 text-yellow-600" />
        </div>
        <h1 class="text-3xl font-bold mb-4">Coming Soon</h1>
        <p class="text-muted-foreground text-lg">{{ data.tenant_name }} is currently under construction.</p>
        <p class="text-muted-foreground">Please check back later!</p>
      </div>
    </div>

    <!-- Landing Page Content -->
    <div v-else-if="data" class="landing-page">
      <!-- Header -->
      <header class="sticky top-0 z-50 bg-background/95 backdrop-blur border-b">
        <div class="container mx-auto px-4 py-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <img 
              v-if="data.branding.logo_url" 
              :src="data.branding.logo_url" 
              :alt="data.tenant_name"
              class="h-10 w-auto"
            />
            <span class="font-bold text-xl">{{ data.tenant_name }}</span>
          </div>
          <div class="flex items-center gap-4">
            <a v-if="data.contact_phone" :href="`tel:${data.contact_phone}`" class="text-sm hover:text-primary">
              <Phone class="h-4 w-4" />
            </a>
            <Button @click="browseCars" size="sm">
              Browse Cars
            </Button>
          </div>
        </div>
      </header>

      <!-- Hero Section -->
      <section class="relative py-20 md:py-32 bg-gradient-to-br from-primary/10 to-secondary/10">
        <div class="container mx-auto px-4 text-center">
          <h1 class="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            {{ data.hero_title }}
          </h1>
          <p class="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            {{ data.hero_subtitle }}
          </p>
          
          <!-- Surf Bar (Search) -->
          <div class="max-w-md mx-auto mb-8 relative">
            <form @submit.prevent="handleSearch" class="relative">
              <input 
                v-model="searchQuery" 
                type="text" 
                placeholder="Search for cars (e.g. BMW, Luxury...)" 
                class="w-full h-12 pl-4 pr-12 rounded-full border-2 border-primary/20 focus:border-primary focus:outline-none transition-all shadow-sm bg-background/50 backdrop-blur"
              />
              <button type="submit" class="absolute right-2 top-1.5 h-9 w-9 bg-primary text-primary-foreground rounded-full flex items-center justify-center hover:bg-primary/90 transition-colors">
                 <Search class="h-4 w-4" />
              </button>
            </form>
          </div>

          <Button size="lg" @click="browseCars" class="text-lg px-8">
            {{ data.hero_cta_text }}
            <ChevronRight class="ml-2 h-5 w-5" />
          </Button>
        </div>
      </section>

      <!-- Features -->
      <section v-if="data.show_features" class="py-16 bg-muted/30">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12">Why Choose Us</h2>
          <div class="grid md:grid-cols-3 gap-8">
            <div class="text-center p-6">
              <div class="w-16 h-16 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <Car class="h-8 w-8 text-primary" />
              </div>
              <h3 class="font-semibold text-lg mb-2">Quality Fleet</h3>
              <p class="text-muted-foreground">Well-maintained vehicles for every need</p>
            </div>
            <div class="text-center p-6">
              <div class="w-16 h-16 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <Shield class="h-8 w-8 text-primary" />
              </div>
              <h3 class="font-semibold text-lg mb-2">Fully Insured</h3>
              <p class="text-muted-foreground">Drive with complete peace of mind</p>
            </div>
            <div class="text-center p-6">
              <div class="w-16 h-16 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <Users class="h-8 w-8 text-primary" />
              </div>
              <h3 class="font-semibold text-lg mb-2">24/7 Support</h3>
              <p class="text-muted-foreground">We're here whenever you need us</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Featured Cars -->
      <section v-if="data.show_fleet && data.cars.length > 0" class="py-16">
        <div class="container mx-auto px-4">
          <div class="flex items-center justify-between mb-8">
            <h2 class="text-3xl font-bold">Featured Cars</h2>
            <Button variant="outline" @click="browseCars">
              View All
              <ChevronRight class="ml-2 h-4 w-4" />
            </Button>
          </div>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card 
              v-for="car in data.cars.slice(0, 6)" 
              :key="car.id"
              class="overflow-hidden cursor-pointer hover:shadow-lg transition-shadow group"
              @click="router.push(`/site/${subdomain}/cars/${car.id}`)"
            >
              <div class="aspect-video bg-muted relative">
                <!-- Image Carousel -->
                <img 
                  v-if="getCurrentImage(car)" 
                  :src="getCurrentImage(car)" 
                  :alt="`${car.brand} ${car.model}`"
                  class="w-full h-full object-cover transition-opacity duration-300"
                />
                <div v-else class="absolute inset-0 flex items-center justify-center">
                  <Car class="h-16 w-16 text-muted-foreground/30" />
                </div>

                <!-- Navigation Arrows (only if multiple images) -->
                <template v-if="car.images && car.images.length > 1">
                  <button 
                    @click.stop="prevImage(car)" 
                    class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/70"
                  >
                    <ChevronLeft class="h-5 w-5" />
                  </button>
                  <button 
                    @click.stop="nextImage(car)" 
                    class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/70"
                  >
                    <ChevronRight class="h-5 w-5" />
                  </button>
                  
                  <!-- Dots Indicator -->
                  <div class="absolute bottom-2 left-1/2 -translate-x-1/2 flex gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
                    <div 
                      v-for="(_, idx) in car.images" 
                      :key="idx" 
                      class="w-1.5 h-1.5 rounded-full transition-colors"
                      :class="imgIndexes[car.id] === idx ? 'bg-white' : 'bg-white/50'"
                    ></div>
                  </div>
                </template>
              </div>
              <CardContent class="p-4">
                <h3 class="font-semibold text-lg">{{ car.brand }} {{ car.model }}</h3>
                <p class="text-sm text-muted-foreground mb-2">{{ car.year }} • {{ car.transmission }} • {{ car.seats }} seats</p>
                <div class="flex items-center justify-between">
                  <span class="text-xl font-bold text-primary">{{ car.daily_rate }} MAD</span>
                  <span class="text-sm text-muted-foreground">/day</span>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <!-- About -->
      <section v-if="data.show_about && data.about_text" class="py-16 bg-muted/30">
        <div class="container mx-auto px-4 max-w-3xl text-center">
          <h2 class="text-3xl font-bold mb-6">About Us</h2>
          <p class="text-lg text-muted-foreground whitespace-pre-line">{{ data.about_text }}</p>
        </div>
      </section>

      <!-- Contact -->
      <section class="py-16">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12">Contact Us</h2>
          <div class="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            <div v-if="data.contact_phone" class="text-center">
              <div class="w-12 h-12 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <Phone class="h-6 w-6 text-primary" />
              </div>
              <a :href="`tel:${data.contact_phone}`" class="hover:text-primary">{{ data.contact_phone }}</a>
            </div>
            <div v-if="data.contact_email" class="text-center">
              <div class="w-12 h-12 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <Mail class="h-6 w-6 text-primary" />
              </div>
              <a :href="`mailto:${data.contact_email}`" class="hover:text-primary">{{ data.contact_email }}</a>
            </div>
            <div v-if="data.contact_address" class="text-center">
              <div class="w-12 h-12 mx-auto mb-4 bg-primary/10 rounded-full flex items-center justify-center">
                <MapPin class="h-6 w-6 text-primary" />
              </div>
              <span>{{ data.contact_address }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Footer -->
      <footer class="py-8 border-t">
        <div class="container mx-auto px-4 flex flex-col md:flex-row items-center justify-between gap-4">
          <p class="text-sm text-muted-foreground">© {{ new Date().getFullYear() }} {{ data.tenant_name }}. All rights reserved.</p>
          <div class="flex items-center gap-4">
            <a v-if="data.social_facebook" :href="data.social_facebook" target="_blank" class="hover:text-primary">
              <Facebook class="h-5 w-5" />
            </a>
            <a v-if="data.social_instagram" :href="data.social_instagram" target="_blank" class="hover:text-primary">
              <Instagram class="h-5 w-5" />
            </a>
          </div>
        </div>
      </footer>

      <!-- WhatsApp Floating Button -->
      <button
        v-if="data.whatsapp_number"
        @click="openWhatsApp"
        class="fixed bottom-6 right-6 w-14 h-14 bg-green-500 hover:bg-green-600 text-white rounded-full shadow-lg flex items-center justify-center z-50 transition-transform hover:scale-110"
      >
        <MessageCircle class="h-7 w-7" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.landing-page {
  --primary-color: #3b82f6;
  --secondary-color: #10b981;
}
</style>
