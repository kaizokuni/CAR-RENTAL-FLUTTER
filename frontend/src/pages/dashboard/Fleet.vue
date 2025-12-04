<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useCarsStore } from '@/stores/cars'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Car as CarIcon, Search, Filter } from 'lucide-vue-next'
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

const carsStore = useCarsStore()
const showAddDialog = ref(false)
const isSubmitting = ref(false)

const newCar = ref({
  make: '',
  model: '',
  year: new Date().getFullYear(),
  license_plate: '',
  price_per_day: 0,
  image_url: ''
})

onMounted(async () => {
  await carsStore.fetchCars()
})

const handleCreateCar = async () => {
  isSubmitting.value = true
  try {
    await carsStore.createCar(newCar.value)
    toast.success('Vehicle added successfully')
    showAddDialog.value = false
    // Reset form
    newCar.value = {
      make: '',
      model: '',
      year: new Date().getFullYear(),
      license_plate: '',
      price_per_day: 0,
      image_url: ''
    }
  } catch (e: any) {
    toast.error('Failed to add vehicle', {
      description: e.message
    })
  } finally {
    isSubmitting.value = false
  }
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'available': return 'bg-green-100 text-green-800'
    case 'rented': return 'bg-blue-100 text-blue-800'
    case 'maintenance': return 'bg-yellow-100 text-yellow-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Fleet Management</h1>
        <p class="text-muted-foreground">Manage your vehicles and their availability.</p>
      </div>
      <Button @click="showAddDialog = true">
        <Plus class="mr-2 h-4 w-4" />
        Add Vehicle
      </Button>
    </div>

    <!-- Filters & Search -->
    <div class="flex items-center gap-4">
      <div class="relative flex-1 max-w-sm">
        <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Search vehicles..." class="pl-8" />
      </div>
      <Button variant="outline">
        <Filter class="mr-2 h-4 w-4" />
        Filter
      </Button>
    </div>
    
    <!-- Loading State -->
    <div v-if="carsStore.isLoading" class="text-center py-12">
      Loading fleet...
    </div>

    <!-- Empty State -->
    <div v-else-if="!carsStore.cars.length" class="border rounded-lg p-12 text-center bg-muted/10">
      <div class="flex justify-center mb-4">
        <div class="p-4 rounded-full bg-background border">
          <CarIcon class="h-8 w-8 text-muted-foreground" />
        </div>
      </div>
      <h3 class="text-lg font-medium">No vehicles found</h3>
      <p class="text-muted-foreground mt-2 mb-6">Get started by adding your first vehicle to the fleet.</p>
      <Button @click="showAddDialog = true">Add Vehicle</Button>
    </div>

    <!-- Cars Grid -->
    <div v-else class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <Card v-for="car in carsStore.cars" :key="car.id" class="overflow-hidden">
        <div class="aspect-video bg-muted relative">
          <img 
            v-if="car.image_url" 
            :src="car.image_url" 
            :alt="`${car.make} ${car.model}`"
            class="w-full h-full object-cover"
          />
          <div v-else class="w-full h-full flex items-center justify-center bg-secondary">
            <CarIcon class="h-12 w-12 text-muted-foreground/50" />
          </div>
          <div class="absolute top-2 right-2">
            <span 
              class="px-2 py-1 rounded-full text-xs font-medium uppercase shadow-sm"
              :class="getStatusColor(car.status)"
            >
              {{ car.status }}
            </span>
          </div>
        </div>
        <CardHeader class="p-4 pb-2">
          <div class="flex justify-between items-start">
            <div>
              <CardTitle class="text-lg">{{ car.make }} {{ car.model }}</CardTitle>
              <CardDescription>{{ car.year }} • {{ car.license_plate }}</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent class="p-4 pt-0">
          <div class="mt-2 flex items-baseline gap-1">
            <span class="text-2xl font-bold">${{ car.price_per_day }}</span>
            <span class="text-muted-foreground text-sm">/day</span>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Add Car Dialog -->
    <Dialog v-model:open="showAddDialog">
      <DialogContent class="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Add New Vehicle</DialogTitle>
          <DialogDescription>
            Enter the details of the new vehicle to add to your fleet.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Make</Label>
              <Input v-model="newCar.make" placeholder="e.g. Toyota" />
            </div>
            <div class="space-y-2">
              <Label>Model</Label>
              <Input v-model="newCar.model" placeholder="e.g. Camry" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Year</Label>
              <Input v-model.number="newCar.year" type="number" />
            </div>
            <div class="space-y-2">
              <Label>License Plate</Label>
              <Input v-model="newCar.license_plate" placeholder="ABC-123" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Price per Day ($)</Label>
            <Input v-model.number="newCar.price_per_day" type="number" min="0" step="0.01" />
          </div>
          <div class="space-y-2">
            <Label>Image URL (Optional)</Label>
            <Input v-model="newCar.image_url" placeholder="https://..." />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showAddDialog = false">Cancel</Button>
          <Button @click="handleCreateCar" :disabled="isSubmitting">
            {{ isSubmitting ? 'Adding...' : 'Add Vehicle' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
