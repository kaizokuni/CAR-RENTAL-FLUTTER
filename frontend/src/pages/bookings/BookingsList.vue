<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useBookingsStore } from '@/stores/bookings'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Plus, Check, X } from 'lucide-vue-next'
import BookingForm from './BookingForm.vue'

const bookingsStore = useBookingsStore()
const isFormOpen = ref(false)

onMounted(() => {
  bookingsStore.fetchBookings()
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold tracking-tight">Bookings</h1>
      <Button @click="isFormOpen = true">
        <Plus class="mr-2 h-4 w-4" /> New Booking
      </Button>
    </div>

    <div v-if="bookingsStore.isLoading" class="text-center py-10">
      Loading bookings...
    </div>

    <div v-else-if="bookingsStore.error" class="text-red-500 py-10">
      {{ bookingsStore.error }}
    </div>

    <div v-else class="grid gap-4">
      <Card v-for="booking in bookingsStore.bookings" :key="booking.id">
        <CardContent class="flex items-center justify-between p-6">
            <div>
                <div class="font-bold text-lg">{{ booking.car_make }} {{ booking.car_model }}</div>
                <div class="text-sm text-muted-foreground">Customer: {{ booking.customer_name || 'Guest' }}</div>
                <div class="text-sm text-muted-foreground">
                    {{ new Date(booking.start_date).toLocaleDateString() }} - {{ new Date(booking.end_date).toLocaleDateString() }}
                </div>
            </div>
            <div class="flex items-center gap-4">
                <div class="text-right">
                    <div class="font-bold">${{ booking.total_price }}</div>
                    <div class="text-sm px-2 py-1 rounded bg-secondary inline-block mt-1">{{ booking.status }}</div>
                </div>
                <div v-if="booking.status === 'Pending'" class="flex gap-2">
                    <Button size="icon" variant="outline" @click="bookingsStore.updateStatus(booking.id, 'Confirmed')">
                        <Check class="h-4 w-4 text-green-600" />
                    </Button>
                    <Button size="icon" variant="outline" @click="bookingsStore.updateStatus(booking.id, 'Cancelled')">
                        <X class="h-4 w-4 text-red-600" />
                    </Button>
                </div>
            </div>
        </CardContent>
      </Card>
      
      <div v-if="bookingsStore.bookings.length === 0" class="text-center py-10 text-muted-foreground">
        No bookings found.
      </div>
    </div>

    <div v-if="isFormOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="bg-background p-6 rounded-lg shadow-lg w-full max-w-md">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-bold">Create Booking</h2>
                <Button variant="ghost" size="sm" @click="isFormOpen = false">X</Button>
            </div>
            <BookingForm @success="isFormOpen = false" />
        </div>
    </div>
  </div>
</template>
