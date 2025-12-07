<script setup lang="ts">
import { ref, watch, computed } from 'vue'

interface Props {
  modelValue: string
  disabled?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

// Plate Types
const isWW = ref(false)

// Moroccan Series Letters (Standard)
const seriesLetters = [
  { value: 'A', arabic: 'أ' },
  { value: 'B', arabic: 'ب' },
  { value: 'D', arabic: 'د' },
  { value: 'H', arabic: 'هـ' },
  { value: 'E', arabic: 'و' },
  { value: 'K', arabic: 'ك' },
  { value: 'L', arabic: 'ل' },
  { value: 'M', arabic: 'م' },
  { value: 'N', arabic: 'ن' },
  { value: 'J', arabic: 'ج' },
  { value: 'F', arabic: 'ف' },
  { value: 'S', arabic: 'ص' },
  { value: 'T', arabic: 'ط' },
]

// Internal state
const plateNumber = ref('')
const plateSeries = ref('A')
const plateRegion = ref('1')

// Initialize from modelValue
watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    if (newVal.includes('WW')) {
      isWW.value = true
      const parts = newVal.split('-')
      plateNumber.value = parts[0] || ''
    } else if (newVal.includes('-')) {
      isWW.value = false
      const parts = newVal.split('-')
      if (parts.length >= 3) {
        plateNumber.value = parts[0] || ''
        plateSeries.value = parts[1] || 'A'
        plateRegion.value = parts[2] || '1'
      }
    }
  }
}, { immediate: true })

// Emit updates
const updatePlate = () => {
  if (isWW.value) {
    emit('update:modelValue', `${plateNumber.value}-WW`)
  } else {
    emit('update:modelValue', `${plateNumber.value}-${plateSeries.value}-${plateRegion.value || '1'}`)
  }
}

watch([isWW, plateNumber, plateSeries, plateRegion], () => {
  updatePlate()
})

// Toggle WW plate type
const toggleWW = () => {
  isWW.value = !isWW.value
}

// Get current letter display
const currentLetter = computed(() => {
  const letter = seriesLetters.find(s => s.value === plateSeries.value)
  return letter ? { latin: letter.value, arabic: letter.arabic } : { latin: 'A', arabic: 'أ' }
})

// Handle series select change
const onSeriesChange = (e: Event) => {
  plateSeries.value = (e.target as HTMLSelectElement).value
}
</script>

<template>
  <div class="flex flex-col gap-3">
    <!-- Type Selector Toggle Button -->
    <button 
      type="button"
      @click="toggleWW"
      class="inline-flex items-center gap-3 px-3 py-2 rounded-lg border text-sm font-medium transition-colors w-fit"
      :class="isWW ? 'bg-primary text-primary-foreground border-primary' : 'bg-muted/40 hover:bg-muted border-input'"
    >
      <span class="relative flex h-5 w-9 items-center rounded-full transition-colors" :class="isWW ? 'bg-primary-foreground/20' : 'bg-input'">
        <span 
          class="absolute h-4 w-4 rounded-full bg-background shadow-sm transition-transform" 
          :class="isWW ? 'translate-x-4' : 'translate-x-0.5'"
        ></span>
      </span>
      WW Plate (Temporary)
    </button>

    <!-- Standard Plate Layout -->
    <div v-if="!isWW" class="flex items-center border-2 border-black dark:border-white rounded-lg bg-white dark:bg-zinc-900 shadow-sm w-full max-w-[380px] overflow-hidden">
      
      <!-- Number Part (Left) -->
      <div class="flex-[3]">
        <label for="plate-number-std" class="sr-only">Plate Number</label>
        <input 
          id="plate-number-std"
          name="plate-number-std"
          v-model="plateNumber" 
          placeholder="12345" 
          autocomplete="off"
          maxlength="5"
          class="h-14 w-full border-0 bg-transparent text-center text-2xl font-bold tracking-widest focus:outline-none focus:ring-0 dark:text-white placeholder:text-zinc-400"
          @input="plateNumber = ($event.target as HTMLInputElement).value.replace(/[^0-9]/g, '').slice(0, 5)"
        />
      </div>

      <!-- Separator -->
      <div class="w-px h-10 bg-black/20 dark:bg-white/30"></div>

      <!-- Series Letter (Middle) - Native Select -->
      <div class="flex-[1.5] flex items-center justify-center">
        <label for="plate-series-std" class="sr-only">Plate Series</label>
        <select 
          id="plate-series-std"
          name="plate-series-std"
          :value="plateSeries"
          @change="onSeriesChange"
          class="h-14 w-full border-0 bg-transparent text-center text-xl font-bold cursor-pointer focus:outline-none focus:ring-0 dark:text-white dark:bg-zinc-900 appearance-none"
        >
          <option v-for="letter in seriesLetters" :key="letter.value" :value="letter.value">
            {{ letter.arabic }} ({{ letter.value }})
          </option>
        </select>
      </div>

      <!-- Separator -->
      <div class="w-px h-10 bg-black/20 dark:bg-white/30"></div>

      <!-- Region Code (Right) -->
      <div class="flex-1">
        <label for="plate-region-std" class="sr-only">Region Code</label>
        <input 
          id="plate-region-std"
          name="plate-region-std"
          v-model="plateRegion" 
          placeholder="1" 
          autocomplete="off"
          maxlength="2"
          class="h-14 w-full border-0 bg-transparent text-center text-xl font-bold focus:outline-none focus:ring-0 dark:text-white placeholder:text-zinc-400"
          @input="plateRegion = ($event.target as HTMLInputElement).value.replace(/[^0-9]/g, '').slice(0, 2)"
        />
      </div>
    </div>

    <!-- WW Plate Layout -->
    <div v-else class="flex items-center border-2 border-black dark:border-white rounded-lg overflow-hidden shadow-sm w-full max-w-[320px]">
      
      <!-- Number Part -->
      <div class="flex-grow bg-white dark:bg-zinc-900">
        <label for="plate-number-ww" class="sr-only">WW Plate Number</label>
        <input 
          id="plate-number-ww"
          name="plate-number-ww"
          v-model="plateNumber" 
          placeholder="123456" 
          autocomplete="off"
          maxlength="6"
          class="h-14 w-full border-0 bg-transparent text-center text-2xl font-bold tracking-widest focus:outline-none focus:ring-0 dark:text-white placeholder:text-zinc-400"
          @input="plateNumber = ($event.target as HTMLInputElement).value.replace(/[^0-9]/g, '').slice(0, 6)"
        />
      </div>

      <!-- WW Part -->
      <div class="bg-black text-white flex items-center justify-center h-14 w-16 shrink-0">
        <span class="text-xl font-bold">WW</span>
      </div>
    </div>

    <!-- <p class="text-xs text-muted-foreground">
      {{ !isWW ? 'Format: 12345 - Letter - Region' : 'Format: Number - WW' }}
    </p> -->
  </div>
</template>
