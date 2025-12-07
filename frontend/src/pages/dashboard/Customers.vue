<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useCustomersStore, type Customer } from '@/stores/customers'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Users, Search, Mail, Phone, CreditCard } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

const customersStore = useCustomersStore()
const showAddDialog = ref(false)
const isSubmitting = ref(false)

const newCustomer = ref({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  license_number: '',
  address: ''
})

onMounted(async () => {
  await customersStore.fetchCustomers()
})

const handleCreateCustomer = async () => {
  if (!newCustomer.value.first_name || !newCustomer.value.last_name || !newCustomer.value.email) {
    toast.error('Please fill in required fields')
    return
  }

  isSubmitting.value = true
  try {
    await customersStore.createCustomer(newCustomer.value)
    toast.success('Customer added successfully')
    showAddDialog.value = false
    newCustomer.value = { first_name: '', last_name: '', email: '', phone: '', license_number: '', address: '' }
  } catch (e: any) {
    toast.error('Failed to add customer', { description: e.message })
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Customers</h1>
        <p class="text-muted-foreground">Manage your customer database.</p>
      </div>
      <Button @click="showAddDialog = true">
        <Plus class="mr-2 h-4 w-4" />
        Add Customer
      </Button>
    </div>

    <!-- Search -->
    <div class="flex items-center gap-4">
      <div class="relative flex-1 max-w-sm">
        <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Search customers..." class="pl-8" />
      </div>
    </div>

    <!-- Loading -->
    <div v-if="customersStore.isLoading" class="text-center py-12">
      Loading customers...
    </div>

    <!-- Empty State -->
    <div v-else-if="!customersStore.customers.length" class="border rounded-lg p-12 text-center bg-muted/10">
      <div class="flex justify-center mb-4">
        <div class="p-4 rounded-full bg-background border">
          <Users class="h-8 w-8 text-muted-foreground" />
        </div>
      </div>
      <h3 class="text-lg font-medium">No customers yet</h3>
      <p class="text-muted-foreground mt-2 mb-6">Add your first customer to get started.</p>
      <Button @click="showAddDialog = true">Add Customer</Button>
    </div>

    <!-- Customers Grid -->
    <div v-else class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <Card v-for="customer in customersStore.customers" :key="customer.id">
        <CardContent class="p-4">
          <div class="flex items-start gap-3">
            <div class="p-2 rounded-full bg-primary/10 text-primary">
              <Users class="h-5 w-5" />
            </div>
            <div class="flex-1 min-w-0">
              <h3 class="font-semibold truncate">{{ customer.first_name }} {{ customer.last_name }}</h3>
              <div class="mt-2 space-y-1 text-sm text-muted-foreground">
                <div class="flex items-center gap-2">
                  <Mail class="h-3.5 w-3.5" />
                  <span class="truncate">{{ customer.email }}</span>
                </div>
                <div v-if="customer.phone" class="flex items-center gap-2">
                  <Phone class="h-3.5 w-3.5" />
                  <span>{{ customer.phone }}</span>
                </div>
                <div v-if="customer.license_number" class="flex items-center gap-2">
                  <CreditCard class="h-3.5 w-3.5" />
                  <span>{{ customer.license_number }}</span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Add Customer Dialog -->
    <Dialog v-model:open="showAddDialog">
      <DialogContent class="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Add Customer</DialogTitle>
          <DialogDescription>
            Enter the customer's details.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>First Name *</Label>
              <Input v-model="newCustomer.first_name" placeholder="John" />
            </div>
            <div class="space-y-2">
              <Label>Last Name *</Label>
              <Input v-model="newCustomer.last_name" placeholder="Doe" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Email *</Label>
            <Input v-model="newCustomer.email" type="email" placeholder="john@example.com" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Phone</Label>
              <Input v-model="newCustomer.phone" placeholder="+1 234 567 890" />
            </div>
            <div class="space-y-2">
              <Label>License Number</Label>
              <Input v-model="newCustomer.license_number" placeholder="DL-123456" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Address</Label>
            <Input v-model="newCustomer.address" placeholder="123 Main St, City" />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showAddDialog = false">Cancel</Button>
          <Button @click="handleCreateCustomer" :disabled="isSubmitting">
            {{ isSubmitting ? 'Adding...' : 'Add Customer' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
