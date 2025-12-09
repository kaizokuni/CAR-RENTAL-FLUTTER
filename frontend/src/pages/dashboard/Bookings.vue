<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useBookingsStore, type Booking } from '@/stores/bookings'
import { useCarsStore } from '@/stores/cars'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Calendar, Search, Filter, Clock, CheckCircle2, XCircle, Car as CarIcon } from 'lucide-vue-next'
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

const bookingsStore = useBookingsStore()
const carsStore = useCarsStore()
const showAddDialog = ref(false)
const isSubmitting = ref(false)

const newBooking = ref({
  car_id: '',
  customer_name: '',
  start_date: '',
  end_date: '',
  total_price: 0
})

onMounted(async () => {
  await Promise.all([
    bookingsStore.fetchBookings(),
    carsStore.fetchCars()
  ])
})

const handleCreateBooking = async () => {
  if (!newBooking.value.car_id || !newBooking.value.customer_name || !newBooking.value.start_date || !newBooking.value.end_date) {
    toast.error('Please fill in all required fields')
    return
  }

  isSubmitting.value = true
  try {
    await bookingsStore.createBooking({
      ...newBooking.value,
      start_date: new Date(newBooking.value.start_date).toISOString(),
      end_date: new Date(newBooking.value.end_date).toISOString()
    })
    toast.success('Booking created successfully')
    showAddDialog.value = false
    newBooking.value = { car_id: '', customer_name: '', start_date: '', end_date: '', total_price: 0 }
  } catch (e: any) {
    toast.error('Failed to create booking', { description: e.message })
  } finally {
    isSubmitting.value = false
  }
}

const handleUpdateStatus = async (booking: Booking, newStatus: string) => {
  try {
    await bookingsStore.updateStatus(booking.id, newStatus)
    toast.success(`Booking ${newStatus}`)
  } catch (e: any) {
    toast.error('Failed to update status')
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'confirmed': return 'bg-green-100 text-green-800'
    case 'pending': return 'bg-yellow-100 text-yellow-800'
    case 'cancelled': return 'bg-red-100 text-red-800'
    case 'completed': return 'bg-blue-100 text-blue-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'confirmed': return CheckCircle2
    case 'pending': return Clock
    case 'cancelled': return XCircle
    case 'completed': return CheckCircle2
    default: return Clock
  }
}

const availableCars = computed(() => {
  return carsStore.cars.filter(car => car.status === 'available')
})
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Bookings</h1>
        <p class="text-muted-foreground">View and manage reservations.</p>
      </div>
      <Button @click="showAddDialog = true">
        <Plus class="mr-2 h-4 w-4" />
        New Booking
      </Button>
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-4">
      <div class="relative flex-1 max-w-sm">
        <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Search bookings..." class="pl-8" />
      </div>
      <Button variant="outline">
        <Filter class="mr-2 h-4 w-4" />
        Filter
      </Button>
    </div>
    
    <!-- Loading -->
    <div v-if="bookingsStore.isLoading" class="text-center py-12">
      Loading bookings...
    </div>

    <!-- Empty State -->
    <div v-else-if="!bookingsStore.bookings.length" class="border rounded-lg p-12 text-center bg-muted/10">
      <div class="flex justify-center mb-4">
        <div class="p-4 rounded-full bg-background border">
          <Calendar class="h-8 w-8 text-muted-foreground" />
        </div>
      </div>
      <h3 class="text-lg font-medium">No bookings yet</h3>
      <p class="text-muted-foreground mt-2 mb-6">Create your first booking to get started.</p>
      <Button @click="showAddDialog = true">New Booking</Button>
    </div>

    <!-- Bookings List -->
    <div v-else class="space-y-4">
      <Card v-for="booking in bookingsStore.bookings" :key="booking.id">
        <CardContent class="p-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="p-2 rounded-lg bg-secondary">
                <CarIcon class="h-6 w-6 text-muted-foreground" />
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-semibold">{{ booking.car_make }} {{ booking.car_model }}</span>
                  <span 
                    class="px-2 py-0.5 rounded-full text-xs font-medium capitalize flex items-center gap-1"
                    :class="getStatusColor(booking.status)"
                  >
                    <component :is="getStatusIcon(booking.status)" class="h-3 w-3" />
                    {{ booking.status }}
                  </span>
                </div>
                <p class="text-sm text-muted-foreground">
                  {{ booking.customer_name }} • {{ formatDate(booking.start_date) }} - {{ formatDate(booking.end_date) }}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-4">
              <div class="text-right">
                <p class="text-lg font-bold">${{ booking.total_price }}</p>
                <p class="text-xs text-muted-foreground">Total</p>
              </div>
              <div class="flex gap-2">
                <Button 
                  v-if="booking.status === 'pending'" 
                  size="sm" 
                  @click="handleUpdateStatus(booking, 'confirmed')"
                >
                  Confirm
                </Button>
                <Button 
                  v-if="booking.status === 'confirmed'" 
                  size="sm" 
                  variant="outline" 
                  @click="handleUpdateStatus(booking, 'completed')"
                >
                  Complete
                </Button>
                <Button 
                  v-if="booking.status === 'pending' || booking.status === 'confirmed'" 
                  size="sm" 
                  variant="destructive"
                  @click="handleUpdateStatus(booking, 'cancelled')"
                >
                  Cancel
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Create Booking Dialog -->
    <Dialog v-model:open="showAddDialog">
      <DialogContent class="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>New Booking</DialogTitle>
          <DialogDescription>
            Create a new reservation for a customer.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="space-y-2">
            <Label>Customer Name</Label>
            <Input v-model="newBooking.customer_name" placeholder="John Doe" />
          </div>
          <div class="space-y-2">
            <Label>Vehicle</Label>
            <Select v-model="newBooking.car_id">
              <SelectTrigger>
                <SelectValue placeholder="Select a vehicle" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem v-for="car in availableCars" :key="car.id" :value="car.id">
                  {{ car.brand }} {{ car.model }} ({{ car.year }}) - ${{ car.price_per_day }}/day
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Start Date</Label>
              <Input v-model="newBooking.start_date" type="date" />
            </div>
            <div class="space-y-2">
              <Label>End Date</Label>
              <Input v-model="newBooking.end_date" type="date" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Total Price ($)</Label>
            <Input v-model.number="newBooking.total_price" type="number" min="0" step="0.01" />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showAddDialog = false">Cancel</Button>
          <Button @click="handleCreateBooking" :disabled="isSubmitting">
            {{ isSubmitting ? 'Creating...' : 'Create Booking' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
