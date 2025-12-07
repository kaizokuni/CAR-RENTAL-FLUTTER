<script setup lang="ts">
import { ref, watch, computed, onMounted } from 'vue'
import { Button } from '@/components/ui/button'
import { Minus, Plus } from 'lucide-vue-next'

interface Props {
  modelValue: number
  min?: number
  max?: number
  step?: number
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  step: 1
})

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

const localValue = ref<number>(props.modelValue)

// Sync from parent
watch(() => props.modelValue, (val) => {
  if (val !== localValue.value) {
    localValue.value = val
  }
}, { immediate: true })

// Ensure initial value is set
onMounted(() => {
  if (localValue.value === undefined || localValue.value === null) {
    localValue.value = props.modelValue || new Date().getFullYear()
  }
})

const clampValue = (val: number): number => {
  let clamped = val
  if (props.min !== undefined && clamped < props.min) clamped = props.min
  if (props.max !== undefined && clamped > props.max) clamped = props.max
  return clamped
}

const increment = () => {
  const newVal = clampValue(localValue.value + props.step)
  localValue.value = newVal
  emit('update:modelValue', newVal)
}

const decrement = () => {
  const newVal = clampValue(localValue.value - props.step)
  localValue.value = newVal
  emit('update:modelValue', newVal)
}

const handleChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  const val = parseInt(target.value, 10)
  if (!isNaN(val)) {
    localValue.value = val
    emit('update:modelValue', val)
  }
}

const handleBlur = () => {
  const clamped = clampValue(localValue.value)
  if (clamped !== localValue.value) {
    localValue.value = clamped
    emit('update:modelValue', clamped)
  }
}

const canDecrement = computed(() => props.min === undefined || localValue.value > props.min)
const canIncrement = computed(() => props.max === undefined || localValue.value < props.max)
</script>

<template>
  <div class="inline-flex items-center h-10 rounded-md border border-input bg-background overflow-hidden">
    <Button
      variant="ghost"
      size="icon"
      type="button"
      @click="decrement"
      :disabled="!canDecrement"
      class="h-full w-10 rounded-none border-r border-input shrink-0"
    >
      <Minus class="h-4 w-4" />
      <span class="sr-only">Decrement</span>
    </Button>
    
    <input 
      type="number"
      :id="id"
      :name="id"
      :value="localValue"
      @input="handleChange"
      @blur="handleBlur"
      class="h-full w-20 text-center font-medium tabular-nums border-0 bg-transparent focus:outline-none focus:ring-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
    />

    <Button
      variant="ghost"
      size="icon"
      type="button"
      @click="increment"
      :disabled="!canIncrement"
      class="h-full w-10 rounded-none border-l border-input shrink-0"
    >
      <Plus class="h-4 w-4" />
      <span class="sr-only">Increment</span>
    </Button>
  </div>
</template>
