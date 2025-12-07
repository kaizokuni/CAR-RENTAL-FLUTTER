<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { AlertCircle } from 'lucide-vue-next'

interface Props {
  modelValue: string
  error?: string
  disabled?: boolean
  required?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  error: '',
  disabled: false,
  required: false
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'blur': []
}>()

// Split the license plate into three parts
const number = ref('')
const letter = ref('')
const region = ref('')

// Parse initial value
watch(() => props.modelValue, (newValue) => {
  if (newValue && newValue.includes('|')) {
    const parts = newValue.split('|').map(p => p.trim())
    if (parts.length === 3) {
      number.value = parts[0] || ''
      letter.value = parts[1] || ''
      region.value = parts[2] || ''
    }
  }
}, { immediate: true })

// Combine parts and emit
const updateValue = () => {
  const value = `${number.value} | ${letter.value} | ${region.value}`
  emit('update:modelValue', value)
}

// Auto-focus next input
const numberRef = ref<HTMLInputElement>()
const letterRef = ref<HTMLInputElement>()
const regionRef = ref<HTMLInputElement>()

const handleNumberInput = () => {
  updateValue()
  if (number.value.length >= 5) {
    letterRef.value?.focus()
  }
}

const handleLetterInput = () => {
  letter.value = letter.value.toUpperCase()
  updateValue()
  if (letter.value.length >= 3) {
    regionRef.value?.focus()
  }
}

const handleRegionInput = () => {
  updateValue()
}

const hasError = computed(() => !!props.error)

const inputClasses = computed(() => {
  return hasError.value ? 'border-destructive focus-visible:ring-destructive' : ''
})

const labelClasses = computed(() => {
  return hasError.value ? 'text-destructive' : ''
})
</script>

<template>
  <div class="grid gap-2">
    <Label :class="labelClasses">
      Moroccan License Plate <span v-if="required" class="text-destructive">*</span>
    </Label>
    <div class="flex items-center gap-2">
      <div class="relative flex-1">
        <Input
          ref="numberRef"
          v-model="number"
          type="text"
          placeholder="12345"
          maxlength="5"
          :disabled="disabled"
          :class="inputClasses"
          class="text-center font-mono"
          @input="handleNumberInput"
          @blur="emit('blur')"
        />
      </div>
      <span class="text-2xl font-bold text-muted-foreground">|</span>
      <div class="relative flex-1">
        <Input
          ref="letterRef"
          v-model="letter"
          type="text"
          placeholder="A"
          maxlength="3"
          :disabled="disabled"
          :class="inputClasses"
          class="text-center font-mono uppercase"
          @input="handleLetterInput"
          @blur="emit('blur')"
        />
      </div>
      <span class="text-2xl font-bold text-muted-foreground">|</span>
      <div class="relative flex-1">
        <Input
          ref="regionRef"
          v-model="region"
          type="text"
          placeholder="26"
          maxlength="2"
          :disabled="disabled"
          :class="inputClasses"
          class="text-center font-mono"
          @input="handleRegionInput"
          @blur="emit('blur')"
        />
      </div>
      <AlertCircle
        v-if="hasError"
        class="h-5 w-5 text-destructive flex-shrink-0"
      />
    </div>
    <p v-if="hasError" class="text-sm text-destructive">
      {{ error }}
    </p>
    <p v-else class="text-xs text-muted-foreground">
      Format: Number (1-5 digits) | Letter (1-3 chars) | Region (2 digits)
    </p>
  </div>
</template>
