<script setup lang="ts">
import { computed } from 'vue'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { AlertCircle } from 'lucide-vue-next'

interface Props {
  modelValue: string | number
  label: string
  error?: string
  type?: string
  placeholder?: string
  required?: boolean
  disabled?: boolean
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  required: false,
  disabled: false,
  error: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: string | number]
  'blur': []
}>()

const hasError = computed(() => !!props.error)

const inputClasses = computed(() => {
  const classes = []
  if (hasError.value) {
    classes.push('border-destructive focus-visible:ring-destructive pr-10')
  }
  if (props.class) {
    classes.push(props.class)
  }
  return classes.join(' ')
})

const labelClasses = computed(() => {
  return hasError.value ? 'text-destructive' : ''
})
</script>

<template>
  <div class="grid gap-2">
    <Label :for="label" :class="labelClasses">
      {{ label }} <span v-if="required" class="text-destructive">*</span>
    </Label>
    <div class="relative">
      <Input
        :id="label"
        :type="type"
        :placeholder="placeholder"
        :required="required"
        :disabled="disabled"
        :model-value="modelValue"
        :class="inputClasses"
        @update:model-value="emit('update:modelValue', $event)"
        @blur="emit('blur')"
      />
      <AlertCircle
        v-if="hasError"
        class="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-destructive"
      />
    </div>
    <p v-if="hasError" class="text-sm text-destructive">
      {{ error }}
    </p>
    <slot name="hint" v-else />
  </div>
</template>
