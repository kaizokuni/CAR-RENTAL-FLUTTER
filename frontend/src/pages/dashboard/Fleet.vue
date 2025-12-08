<script setup lang="ts">
import { ref, onMounted, computed, watch, reactive } from 'vue'
import { useCarsStore, type Car } from '@/stores/cars'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, Car as CarIcon, Search, Filter, ChevronRight, ChevronLeft, CheckCircle2, MoreVertical, Pencil, Trash2, AlertTriangle } from 'lucide-vue-next'
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

// Car Database State
// const carDatabase = ref<any>(null) // Removed duplicate
// const isLoadingDb = ref(false) // Removed duplicate

// Wizard State
const currentStep = ref(1)
const steps = [
  { id: 1, title: 'Vehicle' },
  { id: 2, title: 'Identity' },
  { id: 3, title: 'Gallery' },
  { id: 4, title: 'Pricing' }
]

const newCar = reactive({
  make: '',
  model: '',
  year: new Date().getFullYear(),
  license_plate: '',
  price_per_day: 0,
  currency: 'MAD',
  images: [] as string[]
})

// Validation for Steps
const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1:
      return !!newCar.make && !!newCar.model && !!newCar.year
    case 2:
      // While optional, if length > 0 it should be somewhat valid. 
      // But typically step 2 blocks if empty? 
      // User said "plate is optional input". So always true unless explicit error?
      // Let's enforce basic length if provided, but allow empty steps? 
      // User also said "If I choose to input it...".
      // Let's valid it always to true for now to respect optionality, 
      // or check min length ONLY if not empty.
      return newCar.license_plate.length === 0 || newCar.license_plate.length >= 5
    case 3:
      // Gallery is optional
      return true
    case 4:
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
  currentStep.value = 1
  editingCarId.value = null
  Object.assign(newCar, {
    make: '',
    model: '',
    year: new Date().getFullYear(),
    license_plate: '',
    price_per_day: 0,
    currency: 'MAD',
    images: []
  })
}

// Top Makers - Dynamic from Database or Fallback
// We will use computed to get top makers if available in DB
const topMakers = computed(() => {
  // Static list of top makers we want to show
  const priority = ['Dacia', 'Renault', 'Peugeot', 'Volkswagen', 'Hyundai', 'Mercedes-Benz', 'Toyota', 'Fiat']
  if (!carDatabase.value?.makes) return []
  
  return priority.map(name => {
    const data = carDatabase.value.makes[name]
    return {
       name,
       logo: data?.logo || undefined
    }
  }).filter(m => !!m.name)
})

const selectTopMaker = (maker: string) => {
  newCar.make = maker
  // Clear model when switching make
  newCar.model = '' 
}

import carDatabaseRaw from '@/data/cars_database.json'

// ...

// Car Database State
const carDatabase = ref<any>(carDatabaseRaw) // Initialize directly
// const isLoadingDb = ref(false) // No longer needed

// ...

/* Removed loadCarDatabase function and its call in onMounted */

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
    make: car.make,
    model: car.model,
    year: car.year,
    license_plate: car.license_plate,
    price_per_day: car.price_per_day,
    currency: car.currency || 'MAD',
    images: car.images || (car.image_url ? [car.image_url] : [])
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
  if (!make || !carDatabase.value?.makes) return undefined
  return carDatabase.value.makes[make]?.logo
}

// Computed options for Autocomplete
const makeOptions = computed(() => {
  if (!carDatabase.value?.makes) return []
  return Object.keys(carDatabase.value.makes).map(make => ({
    value: make,
    label: make,
    image: carDatabase.value.makes[make].logo
  }))
})

const modelOptions = computed(() => {
  if (!carDatabase.value?.makes || !newCar.make) return []
  const makeData = carDatabase.value.makes[newCar.make]
  if (!makeData?.models) return []
  
  return Object.keys(makeData.models).map(model => ({
    value: model,
    label: model
  }))
})

// Watchers
watch(() => newCar.make, (newMake) => {
  if (newMake && carDatabase.value?.makes) {
    const makeData = carDatabase.value.makes[newMake]
    if (!makeData) {
       // Custom make
    } else if (newCar.model && !makeData.models[newCar.model] && !editingCarId.value) {
      // Only clear model if NOT editing (to preserve loaded value)
      // Actually, editingCarId check might not be enough if user changes make manually during edit.
      // Better: Check if current model belongs to new make. 
      // BUT for simplicity, if we are editing and just opened, we want to keep it.
      // If user changes make, model SHOULD reset. 
      // The issue is initialization... watch triggers on mounting/assigning.
      
      // Fix: Check if newMake is DIFFERENT from what we had before? 
      // Or simply: if valid model exists for make, keep it?
    }
  }
})

watch(() => newCar.model, (newModel) => {
  if (!newModel || !newCar.make || !carDatabase.value) return
  const makeData = carDatabase.value.makes[newCar.make]
  const modelData = makeData?.models?.[newModel]
  
  // Only auto-set price if it's 0 (new car)
  if (modelData && modelData.suggestedPrice && newCar.price_per_day === 0) {
    newCar.price_per_day = modelData.suggestedPrice
  }
})
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Fleet Management</h1>
        <p class="text-muted-foreground">Manage your vehicles and their availability.</p>
      </div>
      <Button @click="() => { resetForm(); showAddDialog = true }">
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
    
    <!-- Loading/Empty/List States (Existing Code) -->
    <div v-if="carsStore.isLoading" class="text-center py-12">
      Loading fleet...
    </div>

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

    <div v-else class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <Card v-for="car in carsStore.cars" :key="car.id" class="overflow-hidden group hover:shadow-lg transition-shadow relative">
        <div class="aspect-video bg-muted relative group">
          <!-- Show ArrayImages[0] or fallback -->
          <img 
            v-if="car.image_url" 
            :src="car.image_url" 
            :alt="`${car.make} ${car.model}`"
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
          <div class="absolute top-2 left-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="secondary" size="icon" class="h-8 w-8 rounded-full shadow-sm">
                  <MoreVertical class="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start">
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
              <CardTitle class="text-lg">{{ car.make }} {{ car.model }}</CardTitle>
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
               <div class="flex flex-wrap gap-3">
                 <button 
                  v-for="maker in topMakers" 
                  :key="maker.name"
                  type="button"
                  @click="selectTopMaker(maker.name)"
                  class="flex flex-col items-center justify-center w-20 h-20 rounded-xl border-2 transition-all hover:scale-105"
                  :class="newCar.make === maker.name ? 'border-primary bg-primary/5' : 'border-muted bg-background hover:border-primary/50'"
                 >
                   <img v-if="maker.logo" :src="maker.logo" class="w-8 h-8 object-contain mb-2" :alt="maker.name">
                   <div v-else class="w-8 h-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold mb-2">
                     {{ maker.name.substring(0, 1) }}
                   </div>
                   <span class="text-[10px] font-bold text-center truncate w-full px-1">{{ maker.name }}</span>
                 </button>
               </div>
            </div>

            <div class="space-y-4">
               <!-- Make -->
               <div class="space-y-2">
                  <Label>Make <span class="text-destructive">*</span></Label>
                  <Autocomplete
                    v-model="newCar.make"
                    :options="makeOptions"
                    placeholder="Search or Select Make..."
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
                    :disabled="!newCar.make"
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
                   <h4 class="font-medium text-blue-900 dark:text-blue-100">{{ newCar.make }} {{ newCar.model }}</h4>
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

          <!-- Step 4: Pricing -->
          <div v-else-if="currentStep === 4" class="space-y-6">
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
                       <div class="font-medium">{{ newCar.make }} {{ newCar.model }}</div>
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
                v-if="currentStep < 4" 
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
            Are you sure you want to delete <strong>{{ carToDelete?.make }} {{ carToDelete?.model }}</strong>?
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
  </div>
</template>
