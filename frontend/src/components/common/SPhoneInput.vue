<template>
  <div class="flex relative">
    <Button
      variant="outline"
      class="flex gap-1 rounded-e-none rounded-s-lg px-3"
      @click.stop="showDropdown = !showDropdown"
      type="button"
    >
      <FlagComponent :country="selectedCountry" />
      <span class="text-xs">{{ countryDialCode }}</span>
      <ChevronsUpDown class="-mr-2 h-4 w-4 opacity-50" />
    </Button>

    <!-- Country Dropdown -->
    <div
      v-if="showDropdown"
      class="absolute z-50 top-full left-0 mt-1 w-[250px] max-h-[300px] overflow-auto rounded-md border bg-popover shadow-md"
      @click.stop
    >
      <input
        type="text"
        v-model="search"
        placeholder="Search country..."
        class="w-full p-2 border-b text-sm bg-background"
      />
      <div
        v-for="country in filteredCountries"
        :key="country.code"
        class="flex items-center gap-2 p-2 hover:bg-accent cursor-pointer text-sm"
        @click="selectCountry(country)"
      >
        <FlagComponent :country="country.code" />
        <span class="flex-1">{{ country.name }}</span>
        <span class="text-muted-foreground">{{ country.dial }}</span>
      </div>
    </div>

    <Input
      class="rounded-e-lg rounded-s-none flex-1"
      type="tel"
      v-model="localNumber"
      :placeholder="placeholder"
      @input="handleInput"
      @blur="handleBlur"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { ChevronsUpDown } from 'lucide-vue-next'
import FlagComponent from '@/components/common/FlagComponent.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const props = withDefaults(defineProps<{
  modelValue?: string
  defaultCountry?: string
}>(), {
  defaultCountry: 'MA'
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const countries = [
  { code: 'MA', name: 'Morocco', dial: '+212' },
  { code: 'FR', name: 'France', dial: '+33' },
  { code: 'US', name: 'United States', dial: '+1' },
  { code: 'GB', name: 'United Kingdom', dial: '+44' },
  { code: 'ES', name: 'Spain', dial: '+34' },
  { code: 'DE', name: 'Germany', dial: '+49' },
  { code: 'IT', name: 'Italy', dial: '+39' },
  { code: 'BE', name: 'Belgium', dial: '+32' },
  { code: 'NL', name: 'Netherlands', dial: '+31' },
  { code: 'SA', name: 'Saudi Arabia', dial: '+966' },
  { code: 'AE', name: 'UAE', dial: '+971' },
  { code: 'DZ', name: 'Algeria', dial: '+213' },
  { code: 'TN', name: 'Tunisia', dial: '+216' },
  { code: 'EG', name: 'Egypt', dial: '+20' },
]

const showDropdown = ref(false)
const search = ref('')
const selectedCountry = ref(props.defaultCountry)
const localNumber = ref('')
const placeholder = ref('600 000 000')

const countryDialCode = computed(() => {
  const c = countries.find(c => c.code === selectedCountry.value)
  return c?.dial || '+212'
})

const filteredCountries = computed(() => {
  if (!search.value) return countries
  const s = search.value.toLowerCase()
  return countries.filter(c => 
    c.name.toLowerCase().includes(s) || c.dial.includes(s)
  )
})

const selectCountry = (country: typeof countries[0]) => {
  selectedCountry.value = country.code
  showDropdown.value = false
  emitFullNumber()
}

const handleInput = () => {
  // Just update local state, emit on blur or explicit action
}

const handleBlur = () => {
  emitFullNumber()
}

const emitFullNumber = () => {
  if (localNumber.value) {
    emit('update:modelValue', `${countryDialCode.value} ${localNumber.value}`)
  } else {
    emit('update:modelValue', '')
  }
}

// Parse initial value
const parseInitialValue = () => {
  if (props.modelValue) {
    // Try to find dial code and extract number
    for (const country of countries) {
      if (props.modelValue.startsWith(country.dial)) {
        selectedCountry.value = country.code
        localNumber.value = props.modelValue.replace(country.dial, '').trim()
        return
      }
    }
    // Just use the value as number
    localNumber.value = props.modelValue.replace(/^\+\d+\s*/, '')
  }
}

// Close dropdown on click outside
const handleClickOutside = () => {
  showDropdown.value = false
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  parseInitialValue()
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
