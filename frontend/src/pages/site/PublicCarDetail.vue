<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { 
  Car, ArrowLeft, Fuel, Users, Settings, Calendar, Send, Check
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

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
const carId = computed(() => route.params.carId as string)

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

const goBack = () => {
  if (route.params.subdomain) {
    router.push(`/site/${subdomain.value}/cars`)
  } else {
    router.push('/cars')
  }
}

const car = ref<CarData | null>(null)
const isLoading = ref(true)
const isSubmitting = ref(false)
const submitted = ref(false)

// Booking form
const form = ref({
  customer_name: '',
  customer_phone: '',
  customer_email: '',
  pickup_date: '',
  return_date: '',
  pickup_location: '',
  message: ''
})

const fetchCar = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`/api/v1/public/cars/${subdomain.value}/${carId.value}`)
    if (res.ok) {
      car.value = await res.json()
    } else {
      router.push(`/site/${subdomain.value}/cars`)
    }
  } catch (e) {
    console.error('Failed to fetch car:', e)
  } finally {
    isLoading.value = false
  }
}



const submitRequest = async () => {
  if (!form.value.customer_name || !form.value.customer_phone || !form.value.pickup_date || !form.value.return_date) {
    toast.error('Please fill in all required fields')
    return
  }

  isSubmitting.value = true
  try {
    const res = await fetch('/api/v1/public/booking-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        subdomain: subdomain.value,
        car_id: carId.value,
        ...form.value
      })
    })

    if (res.ok) {
      submitted.value = true
      toast.success('Request submitted successfully!')
    } else {
      toast.error('Failed to submit request')
    }
  } catch (e) {
    toast.error('Failed to submit request')
  } finally {
    isSubmitting.value = false
  }
}

// Set minimum dates
const today = new Date().toISOString().split('T')[0]

onMounted(fetchCar)
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
          <h1 class="text-xl font-bold">Car Details</h1>
        </div>
      </div>
    </header>

    <!-- Loading -->
    <div v-if="isLoading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>

    <main v-else-if="car" class="container mx-auto px-4 py-8">
      <div class="grid lg:grid-cols-2 gap-8">
        <!-- Car Info -->
        <div>
          <div class="aspect-video bg-muted rounded-lg overflow-hidden mb-6">
            <img 
              v-if="car.image_url" 
              :src="car.image_url" 
              :alt="`${car.brand} ${car.model}`"
              class="w-full h-full object-cover"
            />
            <div v-else class="h-full flex items-center justify-center">
              <Car class="h-24 w-24 text-muted-foreground/30" />
            </div>
          </div>

          <h1 class="text-3xl font-bold mb-2">{{ car.brand }} {{ car.model }}</h1>
          <p class="text-lg text-muted-foreground mb-6">{{ car.year }}</p>

          <div class="grid grid-cols-3 gap-4 mb-6">
            <div class="text-center p-4 bg-muted/50 rounded-lg">
              <Settings class="h-6 w-6 mx-auto mb-2 text-primary" />
              <span class="text-sm">{{ car.transmission }}</span>
            </div>
            <div class="text-center p-4 bg-muted/50 rounded-lg">
              <Fuel class="h-6 w-6 mx-auto mb-2 text-primary" />
              <span class="text-sm">{{ car.fuel_type }}</span>
            </div>
            <div class="text-center p-4 bg-muted/50 rounded-lg">
              <Users class="h-6 w-6 mx-auto mb-2 text-primary" />
              <span class="text-sm">{{ car.seats }} seats</span>
            </div>
          </div>

          <div class="text-center py-6 bg-primary/5 rounded-lg">
            <span class="text-4xl font-bold text-primary">{{ car.daily_rate }}</span>
            <span class="text-lg text-muted-foreground"> MAD / day</span>
          </div>
        </div>

        <!-- Booking Form -->
        <div>
          <Card>
            <CardHeader>
              <CardTitle class="flex items-center gap-2">
                <Calendar class="h-5 w-5" />
                Request This Car
              </CardTitle>
            </CardHeader>
            <CardContent>
              <!-- Success State -->
              <div v-if="submitted" class="text-center py-8">
                <div class="w-16 h-16 mx-auto mb-4 bg-green-100 rounded-full flex items-center justify-center">
                  <Check class="h-8 w-8 text-green-600" />
                </div>
                <h3 class="text-xl font-semibold mb-2">Request Submitted!</h3>
                <p class="text-muted-foreground mb-4">We'll get back to you soon.</p>
                <Button @click="goBack">Browse More Cars</Button>
              </div>

              <!-- Form -->
              <form v-else @submit.prevent="submitRequest" class="space-y-4">
                <div class="space-y-2">
                  <Label>Full Name *</Label>
                  <Input v-model="form.customer_name" placeholder="Your name" required />
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-2">
                    <Label>Phone *</Label>
                    <Input v-model="form.customer_phone" placeholder="+212 6XX XXX XXX" required />
                  </div>
                  <div class="space-y-2">
                    <Label>Email</Label>
                    <Input v-model="form.customer_email" type="email" placeholder="email@example.com" />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-2">
                    <Label>Pickup Date *</Label>
                    <Input v-model="form.pickup_date" type="date" :min="today" required />
                  </div>
                  <div class="space-y-2">
                    <Label>Return Date *</Label>
                    <Input v-model="form.return_date" type="date" :min="form.pickup_date || today" required />
                  </div>
                </div>

                <div class="space-y-2">
                  <Label>Pickup Location</Label>
                  <Input v-model="form.pickup_location" placeholder="Where should we deliver the car?" />
                </div>

                <div class="space-y-2">
                  <Label>Message</Label>
                  <textarea 
                    v-model="form.message"
                    placeholder="Any special requests or questions?"
                    class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  ></textarea>
                </div>

                <Button type="submit" class="w-full" size="lg" :disabled="isSubmitting">
                  <Send class="mr-2 h-4 w-4" />
                  {{ isSubmitting ? 'Sending...' : 'Send Request' }}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </main>
  </div>
</template>
