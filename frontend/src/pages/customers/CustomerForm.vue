<script setup lang="ts">
import { ref } from 'vue'
import { useCustomersStore } from '@/stores/customers'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const emit = defineEmits(['success'])
const customersStore = useCustomersStore()

const form = ref({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  license_number: '',
  address: ''
})

async function onSubmit() {
  try {
    await customersStore.createCustomer(form.value)
    form.value = {
      first_name: '',
      last_name: '',
      email: '',
      phone: '',
      license_number: '',
      address: ''
    }
    emit('success')
  } catch (e) {
    // Error handled in store
  }
}
</script>

<template>
  <form @submit.prevent="onSubmit" class="space-y-4">
    <div class="grid grid-cols-2 gap-4">
        <div class="grid gap-2">
            <Label for="firstName">First Name</Label>
            <Input id="firstName" v-model="form.first_name" placeholder="John" required />
        </div>
        <div class="grid gap-2">
            <Label for="lastName">Last Name</Label>
            <Input id="lastName" v-model="form.last_name" placeholder="Doe" required />
        </div>
    </div>
    
    <div class="grid gap-2">
      <Label for="email">Email</Label>
      <Input id="email" type="email" v-model="form.email" placeholder="john@example.com" required />
    </div>
    
    <div class="grid gap-2">
      <Label for="phone">Phone</Label>
      <Input id="phone" type="tel" v-model="form.phone" placeholder="+1234567890" />
    </div>

    <div class="grid gap-2">
      <Label for="license">License Number</Label>
      <Input id="license" v-model="form.license_number" placeholder="DL-123456" />
    </div>

    <div class="grid gap-2">
      <Label for="address">Address</Label>
      <Input id="address" v-model="form.address" placeholder="123 Main St, City" />
    </div>

    <div v-if="customersStore.error" class="text-sm text-red-500">
      {{ customersStore.error }}
    </div>

    <Button type="submit" class="w-full" :disabled="customersStore.isLoading">
      {{ customersStore.isLoading ? 'Saving...' : 'Save Customer' }}
    </Button>
  </form>
</template>
