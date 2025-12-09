<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Car, ArrowLeft, Search, Fuel, Users, Settings } from 'lucide-vue-next'

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
const goBack = () => {
  if (route.params.subdomain) {
    router.push(`/site/${subdomain.value}`)
  } else {
    router.push('/')
  }
}
const viewCar = (carId: string) => {
  if (route.params.subdomain) {
    router.push(`/site/${subdomain.value}/cars/${carId}`)
  } else {
    router.push(`/cars/${carId}`)
  }
}

interface CarData {
  id: string
  brand: string
  model: string
  year: number
  daily_rate: number
  image_url: string
  transmission: string
  fuel_type: string
  seats: number
}

const cars = ref<CarData[]>([])
const isLoading = ref(true)
const searchQuery = ref('')

const filteredCars = computed(() => {
  if (!searchQuery.value) return cars.value
  const q = searchQuery.value.toLowerCase()
  return cars.value.filter(car => 
    car.brand.toLowerCase().includes(q) || 
    car.model.toLowerCase().includes(q)
  )
})

const fetchCars = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`/api/v1/public/cars/${subdomain.value}`)
    if (res.ok) {
      cars.value = await res.json()
    }
  } catch (e) {
    console.error('Failed to fetch cars:', e)
  } finally {
    isLoading.value = false
  }
}



onMounted(fetchCars)
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- Header -->
    <header class="sticky top-0 z-50 bg-background/95 backdrop-blur border-b">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center gap-4">
          <Button variant="ghost" size="icon" @click="goBack">
            <ArrowLeft class="h-5 w-5" />
          </Button>
          <h1 class="text-xl font-bold">Available Cars</h1>
        </div>
      </div>
    </header>

    <main class="container mx-auto px-4 py-8">
      <!-- Search -->
      <div class="mb-8 max-w-md">
        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input 
            v-model="searchQuery" 
            placeholder="Search by brand or model..." 
            class="pl-10"
          />
        </div>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="flex justify-center py-12">
        <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>

      <!-- Cars Grid -->
      <div v-else-if="filteredCars.length > 0" class="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <Card 
          v-for="car in filteredCars" 
          :key="car.id"
          class="overflow-hidden cursor-pointer hover:shadow-lg transition-all hover:-translate-y-1"
          @click="viewCar(car.id)"
        >
          <div class="aspect-video bg-muted relative">
            <img 
              v-if="car.image_url" 
              :src="car.image_url" 
              :alt="`${car.brand} ${car.model}`"
              class="w-full h-full object-cover"
            />
            <div v-else class="absolute inset-0 flex items-center justify-center">
              <Car class="h-16 w-16 text-muted-foreground/30" />
            </div>
          </div>
          <CardContent class="p-4">
            <h3 class="font-semibold text-lg mb-1">{{ car.brand }} {{ car.model }}</h3>
            <p class="text-sm text-muted-foreground mb-3">{{ car.year }}</p>
            
            <div class="flex items-center gap-4 text-xs text-muted-foreground mb-3">
              <span class="flex items-center gap-1">
                <Settings class="h-3 w-3" />
                {{ car.transmission }}
              </span>
              <span class="flex items-center gap-1">
                <Fuel class="h-3 w-3" />
                {{ car.fuel_type }}
              </span>
              <span class="flex items-center gap-1">
                <Users class="h-3 w-3" />
                {{ car.seats }}
              </span>
            </div>

            <div class="flex items-baseline gap-1">
              <span class="text-2xl font-bold text-primary">{{ car.daily_rate }}</span>
              <span class="text-sm text-muted-foreground">MAD/day</span>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <Car class="h-16 w-16 mx-auto text-muted-foreground/30 mb-4" />
        <h3 class="text-lg font-medium">No cars found</h3>
        <p class="text-muted-foreground">Try adjusting your search</p>
      </div>
    </main>
  </div>
</template>
