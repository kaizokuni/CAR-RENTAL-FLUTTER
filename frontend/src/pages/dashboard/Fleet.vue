<script setup lang="ts">
import { ref, onMounted, computed, watch, reactive } from 'vue'
import { useCarsStore, type Car } from '@/stores/cars'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Car as CarIcon, Search, Filter, ChevronRight, ChevronLeft, CheckCircle2, MoreVertical, Pencil, Trash2, AlertTriangle, X as LucideX, Eye, CheckCircle, Wrench, Ban, Settings, Zap, Droplet, Users, FileText, Plug, Leaf, Fuel, Gauge, Minus, Construction } from 'lucide-vue-next'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import Autocomplete from '@/components/common/Autocomplete.vue'
import MoroccanLicensePlate from '@/components/fleet/MoroccanLicensePlate.vue'
import MultiImageUpload from '@/components/fleet/MultiImageUpload.vue'
import NumberInput from '@/components/ui/number-input.vue'

const carsStore = useCarsStore()
const showAddDialog = ref(false)
const showDeleteDialog = ref(false)
const isSubmitting = ref(false)
const isDeleting = ref(false)
const editingCarId = ref<string | null>(null)
const carToDelete = ref<Car | null>(null)
const viewingCar = ref<Car | null>(null)

// Search & Filter State
const searchQuery = ref('')
const statusFilter = ref<'all' | 'available' | 'rented' | 'maintenance'>('all')
const showFilters = ref(false)
const brandFilter = ref<string>('')
const yearFilter = ref<string>('')
const fuelFilter = ref<string>('')
const seatsFilter = ref<string>('')

// Filter Options (computed from cars)
const filterOptions = computed(() => {
  const brands = [...new Set(carsStore.cars.map(c => c.brand))].sort()
  const years = [...new Set(carsStore.cars.map(c => c.year))].sort().reverse()
  const fuels = [...new Set(carsStore.cars.map(c => c.fuel_type).filter(Boolean))]
  const seats = [...new Set(carsStore.cars.map(c => c.seats).filter(Boolean))].sort((a, b) => (a || 0) - (b || 0))
  return { brands, years, fuels, seats }
})

// Active filters count
const activeFiltersCount = computed(() => {
  let count = 0
  if (brandFilter.value) count++
  if (yearFilter.value) count++
  if (fuelFilter.value) count++
  if (seatsFilter.value) count++
  return count
})

// Clear all filters
const clearAllFilters = () => {
  searchQuery.value = ''
  statusFilter.value = 'all'
  brandFilter.value = ''
  yearFilter.value = ''
  fuelFilter.value = ''
  seatsFilter.value = ''
}

// Fleet Stats
const fleetStats = computed(() => ({
  total: carsStore.cars.length,
  available: carsStore.cars.filter(c => c.status === 'available').length,
  rented: carsStore.cars.filter(c => c.status === 'rented').length,
  maintenance: carsStore.cars.filter(c => c.status === 'maintenance').length
}))

// Filtered Cars
const filteredCars = computed(() => {
  let cars = carsStore.cars
  
  // Filter by status
  if (statusFilter.value !== 'all') {
    cars = cars.filter(c => c.status === statusFilter.value)
  }
  
  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    cars = cars.filter(c => 
      c.brand.toLowerCase().includes(query) ||
      c.model.toLowerCase().includes(query) ||
      c.license_plate.toLowerCase().includes(query)
    )
  }
  
  // Filter by brand
  if (brandFilter.value) {
    cars = cars.filter(c => c.brand === brandFilter.value)
  }
  
  // Filter by year
  if (yearFilter.value) {
    cars = cars.filter(c => c.year === parseInt(yearFilter.value))
  }
  
  // Filter by fuel type
  if (fuelFilter.value) {
    cars = cars.filter(c => c.fuel_type === fuelFilter.value)
  }
  
  // Filter by seats
  if (seatsFilter.value) {
    cars = cars.filter(c => c.seats === parseInt(seatsFilter.value))
  }
  
  return cars
})

// Car Database State
// const carDatabase = ref<any>(null) // Removed duplicate
// const isLoadingDb = ref(false) // Removed duplicate

// Wizard State
const currentStep = ref(1)
const steps = [
  { id: 1, title: 'Vehicle Info', description: 'Basic details' },
  { id: 2, title: 'Plate Number', description: 'License and region' },
  { id: 3, title: 'Gallery', description: 'Photos' },
  { id: 4, title: 'Details', description: 'Specs' },
  { id: 5, title: 'Pricing', description: 'Rates' }
]
const newCar = reactive({
  brand: '',
  model: '',
  year: new Date().getFullYear(),
  license_plate: '',
  price_per_day: 0,
  currency: 'MAD',
  images: [] as string[],
  transmission: undefined as 'automatic' | 'manual' | undefined,
  fuel_type: undefined as 'electric' | 'hybrid_plugin' | 'hybrid' | 'gasoline' | 'diesel' | undefined,
  seats: 5,
  description: ''
})

// Validation for Steps
const transmissionOptions = [
  { value: 'automatic', label: 'Automatic', icon: Gauge },
  { value: 'manual', label: 'Manual', icon: Construction }
]

const fuelOptions = [
  { value: 'electric', label: 'Electric', icon: Zap },
  { value: 'hybrid_plugin', label: 'Plug-in', icon: Plug },
  { value: 'hybrid', label: 'Hybrid', icon: Leaf },
  { value: 'gasoline', label: 'Gasoline', icon: Fuel },
  { value: 'diesel', label: 'Diesel', icon: Droplet }
]

// Validation for Steps
const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1:
      return !!newCar.brand && !!newCar.model && !!newCar.year
    case 2:
      // While optional, if length > 0 it should be somewhat valid. 
      return newCar.license_plate.length === 0 || newCar.license_plate.length >= 5
    case 3:
      // Gallery is optional
      return true
    case 4:
      // Details - all optional
      return true
    case 5:
      // Pricing
      return newCar.price_per_day > 0
    default:
      return false
  }
})

const nextStep = () => {
  if (currentStep.value < steps.length && isStepValid.value) {
    currentStep.value++
  }
}

const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

// Reset Form
const resetForm = () => {
  newCar.brand = ''
  newCar.model = ''
  newCar.year = new Date().getFullYear()
  newCar.license_plate = ''
  newCar.price_per_day = 0
  newCar.currency = 'MAD'
  newCar.images = []
  newCar.transmission = undefined
  newCar.fuel_type = undefined
  newCar.seats = 5
  newCar.description = ''
  currentStep.value = 1
  editingCarId.value = null
  Object.assign(newCar, {
    brand: '',
    model: '',
    year: new Date().getFullYear(),
    license_plate: '',
    price_per_day: 0,
    currency: 'MAD',
    images: []
  })
}

// Top Brands - Dynamic from Database or Fallback
// We will use computed to get top brands if available in DB
const topBrands = computed(() => {
  // Static list of top brands we want to show
  const priority = ['Dacia', 'Renault', 'Peugeot', 'Volkswagen', 'Hyundai', 'Mercedes-Benz', 'Toyota']
  if (!carDatabase.value?.brands) return []
  
  return priority.map(name => {
    const data = carDatabase.value.brands[name]
    return {
       name,
       logo: data?.logo || undefined
    }
  }).filter(m => !!m.name)
})

const selectTopBrand = (maker: string) => {
  newCar.brand = maker
  // Clear model when switching brand
  newCar.model = '' 
}

import carDatabaseRaw from '@/data/cars_database.json'

// ...

// Car Database State
const carDatabase = ref<any>(carDatabaseRaw) // Initialize directly
// const isLoadingDb = ref(false) // No longer needed

onMounted(async () => {
  await carsStore.fetchCars()
  // Data is already loaded via import
})

const handleCreateOrUpdateCar = async () => {
  isSubmitting.value = true
  try {
    const carData = {
      ...newCar,
      // Map main image_url to the first image if available
      image_url: newCar.images.length > 0 ? newCar.images[0] : ''
    }
    
    if (editingCarId.value) {
      await carsStore.updateCar(editingCarId.value, carData)
      toast.success('Vehicle updated successfully')
    } else {
      await carsStore.createCar(carData)
      toast.success('Vehicle added successfully')
    }
    
    showAddDialog.value = false
    resetForm()
  } catch (e: any) {
    toast.error(editingCarId.value ? 'Failed to update vehicle' : 'Failed to add vehicle', {
      description: e.message
    })
  } finally {
    isSubmitting.value = false
  }
}

const openEditDialog = (car: Car) => {
  editingCarId.value = car.id
  Object.assign(newCar, {
    brand: car.brand,
    model: car.model,
    year: car.year,
    license_plate: car.license_plate,
    price_per_day: car.price_per_day,
    currency: car.currency || 'MAD',
    images: car.images || (car.image_url ? [car.image_url] : []),
    transmission: car.transmission,
    fuel_type: car.fuel_type,
    seats: car.seats || 5,
    description: car.description || ''
  })
  currentStep.value = 1
  showAddDialog.value = true
}

const confirmDelete = (car: Car) => {
  carToDelete.value = car
  showDeleteDialog.value = true
}

const handleDeleteCar = async () => {
  if (!carToDelete.value) return
  
  isDeleting.value = true
  try {
    await carsStore.deleteCar(carToDelete.value.id)
    toast.success('Vehicle deleted successfully')
    showDeleteDialog.value = false
    carToDelete.value = null
  } catch (e: any) {
    toast.error('Failed to delete vehicle', { description: e.message })
  } finally {
    isDeleting.value = false
  }
}

const updateCarStatus = async (newStatus: 'available' | 'rented' | 'maintenance') => {
  if (!viewingCar.value) return
  
  const carId = viewingCar.value.id
  const previousStatus = viewingCar.value.status
  
  // Optimistic update
  viewingCar.value.status = newStatus
  
  try {
    // Now we can send just the status field - backend supports partial updates!
    await carsStore.updateCar(carId, { status: newStatus })
    
    // Re-sync viewingCar with the refreshed store data
    const refreshedCar = carsStore.cars.find(c => c.id === carId)
    if (refreshedCar) {
      viewingCar.value = refreshedCar
    }
    
    toast.success(`Status updated to ${newStatus}`)
  } catch (e: any) {
    // Revert on error
    viewingCar.value.status = previousStatus
    toast.error('Failed to update status', { description: e.message })
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

// Helper to get logo URL
const getLogoUrl = (make: string) => {
  if (!make || !carDatabase.value?.brands) return undefined
  return carDatabase.value.brands[make]?.logo
}

// Computed options for Autocomplete
const makeOptions = computed(() => {
  if (!carDatabase.value?.brands) return []
  return Object.keys(carDatabase.value.brands).map(make => ({
    value: make,
    label: make,
    image: carDatabase.value.brands[make].logo
  }))
})

const modelOptions = computed(() => {
  if (!carDatabase.value?.brands || !newCar.brand) return []
  const makeData = carDatabase.value.brands[newCar.brand]
  if (!makeData?.models) return []
  
  return Object.keys(makeData.models).map(model => ({
    value: model,
    label: model
  }))
})

// Watchers
watch(() => newCar.brand, (newMake) => {
  if (newMake && carDatabase.value?.brands) {
    const makeData = carDatabase.value.brands[newMake]
    if (!makeData) {
       // Custom brand
    } else if (newCar.model && !makeData.models[newCar.model] && !editingCarId.value) {
      // Only clear model if NOT editing (to preserve loaded value)
      // Actually, editingCarId check might not be enough if user changes brand manually during edit.
      // Better: Check if current model belongs to new brand. 
      // BUT for simplicity, if we are editing and just opened, we want to keep it.
      // If user changes brand, model SHOULD reset. 
      // The issue is initialization... watch triggers on mounting/assigning.
      
      // Fix: Check if newMake is DIFFERENT from what we had before? 
      // Or simply: if valid model exists for brand, keep it?
    }
  }
})

watch(() => newCar.model, (newModel) => {
  if (!newModel || !newCar.brand || !carDatabase.value) return
  const makeData = carDatabase.value.brands[newCar.brand]
  const modelData = makeData?.models?.[newModel]
  
  // Only auto-set price if it's 0 (new car)
  if (modelData && modelData.suggestedPrice && newCar.price_per_day === 0) {
    newCar.price_per_day = modelData.suggestedPrice
  }
})
</script>

<template>
  <div class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Your Fleet</h1>
        <p class="text-muted-foreground">Manage your vehicles, track availability, and keep your fleet organized.</p>
      </div>
      <Button @click="() => { resetForm(); showAddDialog = true }">
        <Plus class="mr-2 h-4 w-4" />
        Add Vehicle
      </Button>
    </div>

    <!-- Fleet Stats -->
    <div class="grid gap-4 md:grid-cols-4">
      <Card class="p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-primary/10">
            <CarIcon class="h-5 w-5 text-primary" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ fleetStats.total }}</p>
            <p class="text-xs text-muted-foreground">Total Vehicles</p>
          </div>
        </div>
      </Card>
      <Card class="p-4 cursor-pointer hover:bg-accent/50 transition-colors" @click="statusFilter = 'available'">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-green-500/10">
            <CheckCircle class="h-5 w-5 text-green-500" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ fleetStats.available }}</p>
            <p class="text-xs text-muted-foreground">Available</p>
          </div>
        </div>
      </Card>
      <Card class="p-4 cursor-pointer hover:bg-accent/50 transition-colors" @click="statusFilter = 'rented'">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-blue-500/10">
            <Ban class="h-5 w-5 text-blue-500" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ fleetStats.rented }}</p>
            <p class="text-xs text-muted-foreground">Rented Out</p>
          </div>
        </div>
      </Card>
      <Card class="p-4 cursor-pointer hover:bg-accent/50 transition-colors" @click="statusFilter = 'maintenance'">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-orange-500/10">
            <Wrench class="h-5 w-5 text-orange-500" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ fleetStats.maintenance }}</p>
            <p class="text-xs text-muted-foreground">In Maintenance</p>
          </div>
        </div>
      </Card>
    </div>

    <!-- Search & Filter Tabs -->
    <div class="flex flex-col sm:flex-row items-start sm:items-center gap-4">
      <div class="relative flex-1 max-w-md">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input v-model="searchQuery" placeholder="Search by brand, model, or plate..." class="pl-10" />
      </div>
      <div class="flex gap-1 p-1 bg-muted rounded-lg">
        <Button 
          :variant="statusFilter === 'all' ? 'default' : 'ghost'" 
          size="sm" 
          @click="statusFilter = 'all'"
        >
          All ({{ fleetStats.total }})
        </Button>
        <Button 
          :variant="statusFilter === 'available' ? 'default' : 'ghost'" 
          size="sm" 
          @click="statusFilter = 'available'"
          class="gap-1"
        >
          <CheckCircle class="h-3 w-3" /> Available
        </Button>
        <Button 
          :variant="statusFilter === 'rented' ? 'default' : 'ghost'" 
          size="sm" 
          @click="statusFilter = 'rented'"
          class="gap-1"
        >
          <Ban class="h-3 w-3" /> Rented
        </Button>
        <Button 
          :variant="statusFilter === 'maintenance' ? 'default' : 'ghost'" 
          size="sm" 
          @click="statusFilter = 'maintenance'"
          class="gap-1"
        >
          <Wrench class="h-3 w-3" /> Maintenance
        </Button>
      </div>
      <Button variant="outline" @click="showFilters = !showFilters" class="relative">
        <Filter class="mr-2 h-4 w-4" />
        Filters
        <span v-if="activeFiltersCount > 0" class="absolute -top-2 -right-2 h-5 w-5 rounded-full bg-primary text-[10px] font-medium text-primary-foreground flex items-center justify-center">
          {{ activeFiltersCount }}
        </span>
      </Button>
    </div>

    <!-- Advanced Filters Panel -->
    <div v-if="showFilters" class="border rounded-lg p-4 bg-muted/20">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-sm font-medium">Advanced Filters</h3>
        <Button v-if="activeFiltersCount > 0" variant="ghost" size="sm" @click="clearAllFilters">
          Clear all
        </Button>
      </div>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <!-- Brand Filter -->
        <div class="space-y-2">
          <Label class="text-xs text-muted-foreground">Brand</Label>
          <Select v-model="brandFilter">
            <SelectTrigger>
              <SelectValue placeholder="All brands" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All brands</SelectItem>
              <SelectItem v-for="brand in filterOptions.brands" :key="brand" :value="brand">
                {{ brand }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
        <!-- Year Filter -->
        <div class="space-y-2">
          <Label class="text-xs text-muted-foreground">Year</Label>
          <Select v-model="yearFilter">
            <SelectTrigger>
              <SelectValue placeholder="All years" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All years</SelectItem>
              <SelectItem v-for="year in filterOptions.years" :key="year" :value="String(year)">
                {{ year }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
        <!-- Fuel Type Filter -->
        <div class="space-y-2">
          <Label class="text-xs text-muted-foreground">Fuel Type</Label>
          <Select v-model="fuelFilter">
            <SelectTrigger>
              <SelectValue placeholder="All fuel types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All fuel types</SelectItem>
              <SelectItem v-for="fuel in filterOptions.fuels" :key="fuel" :value="String(fuel)">
                {{ String(fuel).replace('_', ' ') }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
        <!-- Seats Filter -->
        <div class="space-y-2">
          <Label class="text-xs text-muted-foreground">Seats</Label>
          <Select v-model="seatsFilter">
            <SelectTrigger>
              <SelectValue placeholder="All seats" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">All seats</SelectItem>
              <SelectItem v-for="seats in filterOptions.seats" :key="seats" :value="String(seats)">
                {{ seats }} seats
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
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
      <Button @click="() => { resetForm(); showAddDialog = true }">Add Vehicle</Button>
    </div>

    <!-- No Results from Filter -->
    <div v-else-if="!filteredCars.length" class="border rounded-lg p-12 text-center bg-muted/10">
      <div class="flex justify-center mb-4">
        <div class="p-4 rounded-full bg-background border">
          <Search class="h-8 w-8 text-muted-foreground" />
        </div>
      </div>
      <h3 class="text-lg font-medium">No matching vehicles</h3>
      <p class="text-muted-foreground mt-2 mb-6">Try adjusting your search or filter criteria.</p>
      <Button variant="outline" @click="searchQuery = ''; statusFilter = 'all'">Clear Filters</Button>
    </div>

    <!-- Car Grid -->
    <div v-else class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <Card v-for="car in filteredCars" :key="car.id" class="overflow-hidden group hover:shadow-lg transition-shadow relative cursor-pointer" @click="viewingCar = car">
        <div class="aspect-video bg-muted relative group">
          <!-- Show ArrayImages[0] or fallback -->
          <img 
            v-if="car.image_url" 
            :src="car.image_url" 
            :alt="`${car.brand} ${car.model}`"
            class="w-full h-full object-cover"
          />
          <div v-else class="w-full h-full flex items-center justify-center bg-secondary">
            <CarIcon class="h-12 w-12 text-muted-foreground/50" />
          </div>
          
          <div class="absolute top-2 right-2 flex gap-2">
             <span 
               class="px-2 py-1 rounded-full text-xs font-medium uppercase shadow-sm"
               :class="getStatusColor(car.status)"
             >
               {{ car.status }}
             </span>
          </div>

          <!-- Actions Dropdown -->
          <div class="absolute top-2 left-2 opacity-0 group-hover:opacity-100 transition-opacity z-10" @click.stop>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="secondary" size="icon" class="h-8 w-8 rounded-full shadow-lg bg-background/90 backdrop-blur-sm">
                  <MoreVertical class="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start">
                 <DropdownMenuItem @click="viewingCar = car">
                   <Eye class="mr-2 h-4 w-4" />
                   View Details
                 </DropdownMenuItem>
                <DropdownMenuItem @click="openEditDialog(car)">
                  <Pencil class="mr-2 h-4 w-4" />
                  Edit Vehicle
                </DropdownMenuItem>
                <DropdownMenuItem @click="confirmDelete(car)" class="text-destructive focus:text-destructive">
                  <Trash2 class="mr-2 h-4 w-4" />
                  Delete Vehicle
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
        <CardHeader class="p-4 pb-2">
          <div class="flex justify-between items-start">
            <div>
              <CardTitle class="text-lg">{{ car.brand }} {{ car.model }}</CardTitle>
              <CardDescription>{{ car.year }} • {{ car.license_plate }}</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent class="p-4 pt-0">
          <div class="mt-2 flex items-baseline gap-1">
            <span class="text-2xl font-bold">{{ car.price_per_day }}</span>
            <span class="text-muted-foreground text-sm uppercase">{{ car.currency || 'MAD' }} / day</span>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Wizard Dialog -->
    <Dialog v-model:open="showAddDialog">
      <DialogContent class="sm:max-w-[650px] p-0 overflow-hidden">
        <DialogHeader class="px-6 py-4 bg-muted/20 border-b">
          <div class="flex items-center justify-between">
              <DialogTitle class="text-xl">{{ editingCarId ? 'Edit Vehicle' : 'Add New Vehicle' }}</DialogTitle>
              <span class="text-sm text-muted-foreground font-medium">
                  Step {{ currentStep }} / {{ steps.length }}
              </span>
          </div>
          
          <!-- Progress Bar -->
          <div class="h-1 w-full bg-muted mt-4 rounded-full overflow-hidden">
             <div 
               class="h-full bg-primary transition-all duration-300 ease-in-out" 
               :style="{ width: `${(currentStep / steps.length) * 100}%` }"
             ></div>
          </div>
        </DialogHeader>

        <div class="p-6 min-h-[400px]">
          <!-- Step 1: Vehicle Info -->
          <div v-if="currentStep === 1" class="space-y-6">
             <!-- Popular Makers Grid -->
             <div>
               <Label class="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3 block">Quick Select Brand</Label>
               <div class="flex gap-2 overflow-x-auto pb-2">
                 <button 
                  v-for="brand in topBrands" 
                  :key="brand.name"
                  type="button"
                  @click="selectTopBrand(brand.name)"
                  class="flex-shrink-0 flex flex-col items-center justify-center w-[72px] h-[72px] rounded-xl border-2 transition-all hover:scale-105 bg-white text-gray-900"
                  :class="newCar.brand === brand.name ? 'border-primary ring-2 ring-primary/20' : 'border-gray-200 hover:border-primary/50'"
                 >
                   <img v-if="brand.logo" :src="brand.logo" class="w-7 h-7 object-contain mb-1" :alt="brand.name">
                   <div v-else class="w-7 h-7 rounded-full bg-gray-100 flex items-center justify-center text-xs font-bold mb-1">
                     {{ brand.name.substring(0, 1) }}
                   </div>
                   <span class="text-[9px] font-semibold text-center truncate w-full px-1 text-gray-700">{{ brand.name }}</span>
                 </button>
               </div>
            </div>

            <div class="space-y-4">
               <!-- Brand -->
               <div class="space-y-2">
                  <Label>Brand <span class="text-destructive">*</span></Label>
                  <Autocomplete
                    v-model="newCar.brand"
                    :options="makeOptions"
                    placeholder="Search or Select Brand..."
                    class="w-full"
                  />
               </div>
               
               <!-- Model -->
               <div class="space-y-2">
                  <Label>Model <span class="text-destructive">*</span></Label>
                  <Autocomplete
                    v-model="newCar.model"
                    :options="modelOptions"
                    placeholder="Search or Select Model..."
                    :disabled="!newCar.brand"
                    class="w-full"
                  />
               </div>

               <!-- Year (Number Input) -->
               <div class="space-y-2">
                  <Label for="car-year">Year <span class="text-destructive">*</span></Label>
                  <div class="w-40">
                    <NumberInput 
                        id="car-year"
                        v-model="newCar.year" 
                        :min="new Date().getFullYear() - 6" 
                        :max="new Date().getFullYear()" 
                    />
                  </div>
                  <p class="text-xs text-muted-foreground">Vehicle cannot be older than 6 years.</p>
               </div>
            </div>
          </div>

          <!-- Step 2: Identity (Plate) -->
          <div v-else-if="currentStep === 2" class="space-y-6">
            <div class="bg-blue-50/50 dark:bg-blue-950/20 border border-blue-100 dark:border-blue-900 p-4 rounded-lg flex gap-4 items-center mb-6">
                 <div class="h-12 w-12 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center text-blue-600 dark:text-blue-400 shrink-0">
                    <CarIcon class="h-6 w-6" />
                 </div>
                 <div>
                   <h4 class="font-medium text-blue-900 dark:text-blue-100">{{ newCar.brand }} {{ newCar.model }}</h4>
                   <p class="text-sm text-blue-700 dark:text-blue-300">{{ newCar.year }} Model</p>
                 </div>
            </div>

            <div class="space-y-2">
              <Label>License Plate <span class="text-muted-foreground font-normal ml-1">(Optional)</span></Label>
              <MoroccanLicensePlate v-model="newCar.license_plate" />
            </div>
          </div>

          <!-- Step 3: Gallery -->
          <div v-else-if="currentStep === 3" class="space-y-6">
             <div class="space-y-2 h-full">
                <div class="flex justify-between items-center mb-2">
                   <Label>Vehicle Gallery</Label>
                   <span class="text-xs text-muted-foreground">First image will be the cover</span>
                </div>
                <MultiImageUpload v-model="newCar.images" :max-images="10" />
             </div>
          </div>

          <!-- Step 4: Additional Details -->
          <div v-else-if="currentStep === 4" class="space-y-6">
            <div class="space-y-6 h-full p-1">
              
              <!-- Transmission -->
              <div class="space-y-3">
                 <Label class="text-base font-semibold">Transmission</Label>
                 <RadioGroup v-model="newCar.transmission" class="grid grid-cols-2 gap-4">
                   <Label
                     v-for="item in transmissionOptions"
                     :key="item.value"
                     :for="item.value"
                     class="relative flex cursor-pointer flex-col items-center gap-3 rounded-xl border-2 px-4 py-4 text-center shadow-sm hover:bg-accent/50 transition-all duration-200"
                     :class="newCar.transmission === item.value ? 'border-primary bg-primary/5 ring-1 ring-primary' : 'border-muted bg-transparent'"
                   >
                      <RadioGroupItem :id="item.value" :value="item.value" class="sr-only" />
                      <component :is="item.icon" class="h-8 w-8" :class="newCar.transmission === item.value ? 'text-primary' : 'text-muted-foreground'" />
                      <span class="text-sm font-medium" :class="newCar.transmission === item.value ? 'text-foreground' : 'text-muted-foreground'">{{ item.label }}</span>
                   </Label>
                 </RadioGroup>
              </div>

              <!-- Fuel Type -->
              <div class="space-y-3">
                 <Label class="text-base font-semibold">Fuel Type</Label>
                 <RadioGroup v-model="newCar.fuel_type" class="grid grid-cols-3 sm:grid-cols-5 gap-3">
                   <Label
                     v-for="item in fuelOptions"
                     :key="item.value"
                     :for="item.value"
                     class="relative flex cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 px-2 py-3 text-center shadow-sm hover:bg-accent/50 transition-all duration-200"
                     :class="newCar.fuel_type === item.value ? 'border-primary bg-primary/5 ring-1 ring-primary' : 'border-muted bg-transparent'"
                   >
                      <RadioGroupItem :id="item.value" :value="item.value" class="sr-only" />
                      <component :is="item.icon" class="h-6 w-6" :class="newCar.fuel_type === item.value ? 'text-primary' : 'text-muted-foreground'" />
                      <span class="text-xs font-medium leading-tight" :class="newCar.fuel_type === item.value ? 'text-foreground' : 'text-muted-foreground'">{{ item.label }}</span>
                   </Label>
                 </RadioGroup>
              </div>

              <!-- Seats & Description -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                 <!-- Seats -->
                 <div class="space-y-3">
                    <Label class="text-base font-semibold">Seats</Label>
                    <div class="flex items-center gap-4 bg-muted/20 p-2 rounded-xl border w-fit">
                       <Button 
                         variant="outline" 
                         size="icon" 
                         class="h-10 w-10 rounded-lg hover:bg-background hover:text-foreground"
                         @click="newCar.seats > 2 ? newCar.seats-- : null" 
                         :disabled="newCar.seats <= 2"
                       >
                         <Minus class="h-5 w-5" />
                       </Button>
                       <div class="text-2xl font-bold w-12 text-center tabular-nums">{{ newCar.seats }}</div>
                       <Button 
                         variant="outline" 
                         size="icon" 
                         class="h-10 w-10 rounded-lg hover:bg-background hover:text-foreground"
                         @click="newCar.seats < 15 ? newCar.seats++ : null" 
                         :disabled="newCar.seats >= 15"
                       >
                         <Plus class="h-5 w-5" />
                       </Button>
                    </div>
                 </div>

                 <!-- Description -->
                 <div class="space-y-3">
                    <Label for="description" class="text-base font-semibold">Description</Label>
                    <textarea 
                      id="description" 
                      v-model="newCar.description" 
                      class="flex min-h-[100px] w-full rounded-xl border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 resize-none"
                      placeholder="Add specific details..."
                    ></textarea>
                 </div>
              </div>
            </div>
          </div>
           
           <!-- Step 5: Pricing -->
           <div v-else-if="currentStep === 5" class="space-y-6">
              <div class="space-y-4">
                <Label class="text-base">Set Daily Rate</Label>
                
                <div class="flex items-center gap-4">
                   <!-- Price Input -->
                   <div class="relative flex-1">
                      <label for="price-per-day" class="sr-only">Daily Rate</label>
                      <Input 
                        id="price-per-day"
                        name="price-per-day"
                        v-model.number="newCar.price_per_day" 
                        type="number" 
                        min="0" 
                        class="text-3xl font-bold h-16 pl-4 tracking-tight"
                        placeholder="0"
                      />
                   </div>

                   <!-- Currency Select -->
                   <div class="w-32">
                       <label for="currency-select" class="sr-only">Currency</label>
                       <Select v-model="newCar.currency">
                          <SelectTrigger id="currency-select" class="h-16 w-full text-lg font-bold">
                             <SelectValue placeholder="MAD" />
                          </SelectTrigger>
                          <SelectContent>
                             <SelectItem value="MAD">MAD</SelectItem>
                             <SelectItem value="USD">USD</SelectItem>
                             <SelectItem value="EUR">EUR</SelectItem>
                          </SelectContent>
                       </Select>
                   </div>
                </div>

                <!-- Review Card -->
                 <div class="border rounded-xl p-5 bg-muted/30 grid grid-cols-2 gap-y-4 gap-x-8 mt-6">
                    <div class="col-span-2 text-sm font-medium text-muted-foreground uppercase tracking-wider mb-2">Summary</div>
                    
                    <div class="space-y-1">
                       <span class="text-xs text-muted-foreground">Vehicle</span>
                       <div class="font-medium">{{ newCar.brand }} {{ newCar.model }}</div>
                       <div class="text-xs">{{ newCar.year }}</div>
                    </div>

                    <div class="space-y-1 text-right">
                       <span class="text-xs text-muted-foreground">Daily Rate</span>
                       <div class="font-bold text-xl text-primary">{{ newCar.price_per_day }} {{ newCar.currency }}</div>
                    </div>

                    <div class="space-y-1">
                       <span class="text-xs text-muted-foreground">Plate</span>
                       <div class="font-mono text-sm bg-background px-2 py-1 rounded inline-block border">{{ newCar.license_plate || 'Not set' }}</div>
                    </div>

                     <div class="space-y-1 text-right">
                       <span class="text-xs text-muted-foreground">Gallery</span>
                       <div class="text-sm">{{ newCar.images.length }} photos</div>
                    </div>
                 </div>
             </div>
          </div>


        </div>

        <DialogFooter class="px-6 py-4 border-t bg-muted/10 flex items-center justify-between w-full">
          <div class="flex-1">
             <Button v-if="currentStep > 1" variant="ghost" @click="prevStep">
                <ChevronLeft class="mr-2 h-4 w-4" />
                Back
             </Button>
             <Button v-else variant="outline" @click="showAddDialog = false">Cancel</Button>
          </div>
          
          <div class="flex gap-4">
             <!-- Cancel only on Step 1 -->
             <Button 
                v-if="currentStep === 1" 
                variant="outline" 
                @click="showAddDialog = false"
                class="hidden" 
             >
                Cancel
             </Button>

             <Button 
                v-if="currentStep < 5" 
                @click="nextStep" 
                :disabled="!isStepValid"
             >
                Next
                <ChevronRight class="ml-2 h-4 w-4" />
             </Button>
            
            <Button 
                v-else 
                @click="handleCreateOrUpdateCar" 
                :disabled="isSubmitting || !isStepValid"
                class="bg-green-600 hover:bg-green-700 text-white min-w-[120px]"
            >
                <div v-if="isSubmitting" class="flex items-center">
                    <span class="animate-spin mr-2">⏳</span> {{ editingCarId ? 'Updating...' : 'Saving...' }}
                </div>
                <div v-else class="flex items-center">
                    <CheckCircle2 class="mr-2 h-4 w-4" />
                    {{ editingCarId ? 'Update Vehicle' : 'Finish' }}
                </div>
            </Button>
          </div>
        </DialogFooter>
        <!-- Custom Close Button -->
        <button 
          @click="showAddDialog = false"
          class="absolute right-4 top-4 rounded-full bg-red-100 p-2 text-red-600 hover:bg-red-200 transition-colors focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
        >
          <span class="sr-only">Close</span>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
      </DialogContent>
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog v-model:open="showDeleteDialog">
      <DialogContent>
        <DialogHeader>
          <div class="flex items-center gap-2 mb-2">
            <div class="p-2 rounded-full bg-red-100 text-red-600">
               <AlertTriangle class="h-6 w-6" />
            </div>
            <DialogTitle class="text-xl text-red-600">Delete Vehicle</DialogTitle>
          </div>
          <DialogDescription>
            Are you sure you want to delete <strong>{{ carToDelete?.brand }} {{ carToDelete?.model }}</strong>?
            <br/><br/>
            This action cannot be undone. If this vehicle has active bookings, you might need to resolve them first.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" @click="showDeleteDialog = false">Cancel</Button>
          <Button variant="destructive" @click="handleDeleteCar" :disabled="isDeleting">
            {{ isDeleting ? 'Deleting...' : 'Delete Vehicle' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Details Sheet/Drawer -->
    <div 
       v-if="viewingCar" 
       class="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm"
       @click="viewingCar = null"
    ></div>
    <div 
      class="fixed inset-y-0 right-0 z-50 h-full w-full border-l bg-background p-6 shadow-lg transition-transform sm:max-w-md duration-300 ease-in-out transform"
      :class="viewingCar ? 'translate-x-0' : 'translate-x-full'"
    >
      <div v-if="viewingCar" class="flex h-full flex-col gap-6">
         <!-- Header -->
        <div class="flex items-start justify-between">
           <div>
              <h2 class="text-2xl font-bold">{{ viewingCar.brand }} {{ viewingCar.model }}</h2>
              <p class="text-muted-foreground">{{ viewingCar.year }} • {{ viewingCar.license_plate }}</p>
           </div>
           <Button variant="ghost" size="icon" @click="viewingCar = null">
             <LucideX class="h-5 w-5" />
           </Button>
        </div>
        
        <!-- Image Cover -->
        <div class="relative aspect-video w-full overflow-hidden rounded-lg bg-muted">
           <img 
            v-if="viewingCar.image_url"
            :src="viewingCar.image_url" 
            class="h-full w-full object-cover"
            alt="Car Cover"
           />
           <div v-else class="flex h-full w-full items-center justify-center">
             <CarIcon class="h-12 w-12 text-muted-foreground/30" />
           </div>
        </div>

        <!-- Status Update Section -->
        <div class="space-y-2 border-t pt-4">
           <Label class="text-sm font-semibold">Vehicle Status</Label>
           <div class="flex gap-2">
             <Button 
               @click="updateCarStatus('available')" 
               :variant="viewingCar.status === 'available' ? 'default' : 'outline'" 
               size="sm" 
               class="flex-1"
             >
               <CheckCircle class="mr-2 h-4 w-4" />
               Available
             </Button>
             <Button 
               @click="updateCarStatus('rented')" 
               :variant="viewingCar.status === 'rented' ? 'default' : 'outline'" 
               size="sm" 
               class="flex-1"
             >
               <Ban class="mr-2 h-4 w-4" />
               Rented
             </Button>
             <Button 
               @click="updateCarStatus('maintenance')" 
               :variant="viewingCar.status === 'maintenance' ? 'default' : 'outline'" 
               size="sm" 
               class="flex-1"
             >
               <Wrench class="mr-2 h-4 w-4" />
               Maintenance
             </Button>
           </div>
        </div>

        <!-- Gallery Grid -->
        <div v-if="viewingCar.images && viewingCar.images.length > 1" class="space-y-2">
           <h3 class="font-semibold text-sm text-foreground/80">Gallery</h3>
           <div class="grid grid-cols-4 gap-2">
              <div 
                v-for="(img, idx) in viewingCar.images" 
                :key="idx" 
                class="aspect-square overflow-hidden rounded-md bg-muted cursor-pointer hover:ring-2 hover:ring-primary/50"
                @click="viewingCar.image_url = img" 
              >
                 <img :src="img" class="h-full w-full object-cover" />
              </div>
           </div>
        </div>

        <!-- Details List -->
        <div class="grid grid-cols-2 gap-4 border-t pt-4">
           <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Daily Rate</span>
              <div class="font-bold text-xl">{{ viewingCar.price_per_day }} {{ viewingCar.currency }}</div>
           </div>
           <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">License Plate</span>
              <div class="font-medium font-mono bg-muted px-2 py-0.5 rounded inline-block text-sm">{{ viewingCar.license_plate }}</div>
           </div>
           <div v-if="viewingCar.transmission" class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase flex items-center gap-1">
                <Settings class="h-3 w-3" />
                Transmission
              </span>
              <div class="text-sm font-medium capitalize">{{ viewingCar.transmission }}</div>
           </div>
           <div v-if="viewingCar.fuel_type" class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase flex items-center gap-1">
                <Zap v-if="viewingCar.fuel_type === 'electric' || viewingCar.fuel_type.includes('hybrid')" class="h-3 w-3" />
                <Droplet v-else class="h-3 w-3" />
                Fuel Type
              </span>
              <div class="text-sm font-medium capitalize">{{ viewingCar.fuel_type.replace('_', ' ') }}</div>
           </div>
           <div v-if="viewingCar.seats" class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase flex items-center gap-1">
                <Users class="h-3 w-3" />
                Seats
              </span>
              <div class="text-sm font-medium">{{ viewingCar.seats }} Seats</div>
           </div>
           <div class="space-y-1">
              <span class="text-xs text-muted-foreground uppercase">Created At</span>
              <div class="text-sm font-medium">{{ viewingCar.created_at ? new Date(viewingCar.created_at).toLocaleDateString() : '-' }}</div>
           </div>
        </div>
        
        <!-- Description -->
        <div v-if="viewingCar.description" class="space-y-2 border-t pt-4">
          <span class="text-xs text-muted-foreground uppercase flex items-center gap-1">
            <FileText class="h-3 w-3" />
            Description
          </span>
          <p class="text-sm text-foreground/80">{{ viewingCar.description }}</p>
        </div>

        
        <div class="flex-1"></div>
        <!-- Footer Actions -->
        <div class="flex gap-2 border-t pt-4">
           <Button class="flex-1" @click="() => { openEditDialog(viewingCar!); viewingCar = null; }">
             <Pencil class="mr-2 h-4 w-4" />
             Edit Vehicle
           </Button>
           <Button variant="outline" class="flex-1 text-destructive hover:bg-destructive/10" @click="() => { confirmDelete(viewingCar!); viewingCar = null; }">
             <Trash2 class="mr-2 h-4 w-4" />
             Delete
           </Button>
        </div>
      </div>
    </div>
  </div>
</template>
