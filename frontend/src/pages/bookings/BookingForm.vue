<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useBookingsStore } from '@/stores/bookings'
import { useCarsStore } from '@/stores/cars'
import { useCustomersStore } from '@/stores/customers'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const emit = defineEmits(['success'])
const bookingsStore = useBookingsStore()
const carsStore = useCarsStore()
const customersStore = useCustomersStore()

const form = ref({
  car_id: '',
  customer_id: '',
  start_date: '',
  end_date: ''
})

onMounted(() => {
    carsStore.fetchCars()
    customersStore.fetchCustomers()
})

const selectedCar = computed(() => carsStore.cars.find(c => c.id === form.value.car_id))

const estimatedPrice = computed(() => {
    if (!selectedCar.value || !form.value.start_date || !form.value.end_date) return 0
    const start = new Date(form.value.start_date)
    const end = new Date(form.value.end_date)
    const diffTime = Math.abs(end.getTime() - start.getTime())
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    return diffDays * selectedCar.value.price_per_day
})

async function onSubmit() {
  try {
    await bookingsStore.createBooking({
        ...form.value,
        start_date: new Date(form.value.start_date).toISOString(),
        end_date: new Date(form.value.end_date).toISOString()
    })
    emit('success')
  } catch (e) {
    // Error handled in store
  }
}
</script>

<template>
  <form @submit.prevent="onSubmit" class="space-y-4">
    <div class="grid gap-2">
      <Label for="car">Car</Label>
      <select id="car" v-model="form.car_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" required>
        <option value="" disabled>Select a car</option>
        <option v-for="car in carsStore.cars" :key="car.id" :value="car.id">
            {{ car.brand }} {{ car.model }} (${{ car.price_per_day }}/day)
        </option>
      </select>
    </div>

    <div class="grid gap-2">
      <Label for="customer">Customer</Label>
      <select id="customer" v-model="form.customer_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" required>
        <option value="" disabled>Select a customer</option>
        <option v-for="cust in customersStore.customers" :key="cust.id" :value="cust.id">
            {{ cust.first_name }} {{ cust.last_name }}
        </option>
      </select>
    </div>

    <div class="grid grid-cols-2 gap-4">
        <div class="grid gap-2">
            <Label for="start">Start Date</Label>
            <Input id="start" type="date" v-model="form.start_date" required />
        </div>
        <div class="grid gap-2">
            <Label for="end">End Date</Label>
            <Input id="end" type="date" v-model="form.end_date" required />
        </div>
    </div>

    <div v-if="estimatedPrice > 0" class="text-right font-bold">
        Estimated Total: ${{ estimatedPrice.toFixed(2) }}
    </div>

    <div v-if="bookingsStore.error" class="text-sm text-red-500">
      {{ bookingsStore.error }}
    </div>

    <Button type="submit" class="w-full" :disabled="bookingsStore.isLoading">
      {{ bookingsStore.isLoading ? 'Creating...' : 'Create Booking' }}
    </Button>
  </form>
</template>
