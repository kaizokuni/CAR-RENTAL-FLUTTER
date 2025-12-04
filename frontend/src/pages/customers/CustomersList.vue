<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useCustomersStore } from '@/stores/customers'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Plus, Phone, Mail, FileText } from 'lucide-vue-next'
import CustomerForm from './CustomerForm.vue'

const customersStore = useCustomersStore()
const isFormOpen = ref(false)

onMounted(() => {
  customersStore.fetchCustomers()
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold tracking-tight">Customers</h1>
      <Button @click="isFormOpen = true">
        <Plus class="mr-2 h-4 w-4" /> Add Customer
      </Button>
    </div>

    <div v-if="customersStore.isLoading" class="text-center py-10">
      Loading customers...
    </div>

    <div v-else-if="customersStore.error" class="text-red-500 py-10">
      {{ customersStore.error }}
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <Card v-for="customer in customersStore.customers" :key="customer.id">
        <CardHeader>
          <CardTitle>{{ customer.first_name }} {{ customer.last_name }}</CardTitle>
          <CardDescription>{{ customer.address || 'No address provided' }}</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="flex flex-col gap-2 text-sm">
            <div class="flex items-center gap-2">
              <Mail class="h-4 w-4 text-muted-foreground" />
              <span>{{ customer.email }}</span>
            </div>
            <div class="flex items-center gap-2">
              <Phone class="h-4 w-4 text-muted-foreground" />
              <span>{{ customer.phone || 'N/A' }}</span>
            </div>
            <div class="flex items-center gap-2">
              <FileText class="h-4 w-4 text-muted-foreground" />
              <span>License: {{ customer.license_number || 'N/A' }}</span>
            </div>
          </div>
        </CardContent>
      </Card>
      
      <div v-if="customersStore.customers.length === 0" class="col-span-full text-center py-10 text-muted-foreground">
        No customers found. Add your first customer.
      </div>
    </div>

    <div v-if="isFormOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="bg-background p-6 rounded-lg shadow-lg w-full max-w-md">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-bold">Add New Customer</h2>
                <Button variant="ghost" size="sm" @click="isFormOpen = false">X</Button>
            </div>
            <CustomerForm @success="isFormOpen = false" />
        </div>
    </div>
  </div>
</template>
