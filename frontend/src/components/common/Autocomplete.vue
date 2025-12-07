<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { Input } from '@/components/ui/input'
import { ChevronsUpDown, Check } from 'lucide-vue-next'
import { cn } from '@/lib/utils'

interface Option {
  value: string
  label: string
  image?: string
}

interface Props {
  options: Option[]
  modelValue: string
  placeholder?: string
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: 'Select...',
  disabled: false
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'select': [option: Option]
}>()

const isOpen = ref(false)
const searchQuery = ref('')
const inputRef = ref<HTMLInputElement | null>(null)
const listRef = ref<HTMLElement | null>(null)
const focusedIndex = ref(-1)

// Initialize search query with current value's label if exists
watch(() => props.modelValue, (newVal) => {
  const option = props.options.find(o => o.value === newVal)
  // Only update search query if not currently editing (to avoid messing up typing)
  if (option && !isOpen.value) {
    searchQuery.value = option.label
  } else if (!newVal && !isOpen.value) {
    searchQuery.value = ''
  }
}, { immediate: true })

const filteredOptions = computed(() => {
  const query = searchQuery.value.toLowerCase().trim()
  if (!query) return props.options
  return props.options.filter(option => 
    option.label.toLowerCase().includes(query)
  ).slice(0, 6)
})

const handleInput = (e: Event) => {
  const newVal = (e.target as HTMLInputElement).value
  searchQuery.value = newVal
  isOpen.value = true
  focusedIndex.value = -1
  
  // Combobox mode: Allow custom values immediately
  emit('update:modelValue', newVal)
}

const handleFocus = () => {
  if (props.disabled) return
  isOpen.value = true
  // Reset query if it matches current value to allow fresh search?
  // Or keep it? If we want to edit, keeping it is better.
}

const handleClickOutside = (e: MouseEvent) => {
  const target = e.target as HTMLElement
  if (!target.closest('.autocomplete-container')) {
    isOpen.value = false
    // If we are strictly selecting from list, we might revert.
    // But user wants "add a maker that new", so we kept the custom value.
    // We just ensure searchQuery syncs if an option WAS selected.
    const option = props.options.find(o => o.value === props.modelValue)
    if (option && option.label !== searchQuery.value) {
       // If the value matches an option but label is different (e.g. case insensitive match?), sync it.
       // Actually, let's just leave it as is to allow "Toyota" vs "toyota".
    }
  }
}

const selectOption = (option: Option) => {
  emit('update:modelValue', option.value)
  emit('select', option)
  searchQuery.value = option.label
  isOpen.value = false
}

// Keyboard navigation
const handleKeydown = (e: KeyboardEvent) => {
  if (!isOpen.value && (e.key === 'ArrowDown' || e.key === 'Enter')) {
    isOpen.value = true
    return
  }
  
  if (e.key === 'Enter' && !isOpen.value) {
     return // Allow default form submission if closed
  }

  switch (e.key) {
    case 'ArrowDown':
      e.preventDefault()
      focusedIndex.value = (focusedIndex.value + 1) % filteredOptions.value.length
      scrollToFocused()
      break
    case 'ArrowUp':
      e.preventDefault()
      focusedIndex.value = (focusedIndex.value - 1 + filteredOptions.value.length) % filteredOptions.value.length
      scrollToFocused()
      break
    case 'Enter':
      // If menu is open and we have a focused item, select it.
      // If no focused item, we just keep the typed text (already emitted in handleInput) and close.
      if (isOpen.value) {
        e.preventDefault()
        if (focusedIndex.value >= 0) {
          const option = filteredOptions.value[focusedIndex.value]
          if (option) {
              selectOption(option)
          }
        } else {
          // No option focused, just close
          isOpen.value = false
        }
      }
      break
    case 'Escape':
      isOpen.value = false
      break
    case 'Tab':
      isOpen.value = false
      break
  }
}

const scrollToFocused = () => {
  nextTick(() => {
    if (!listRef.value) return
    const items = listRef.value.querySelectorAll('div[data-highlighted="true"]')
    // easier to just use index if children match 1:1, but filteredOptions changes.
    // We already use index in v-for.
    const item = listRef.value.children[focusedIndex.value] as HTMLElement
    if (item) {
      item.scrollIntoView({ block: 'nearest' })
    }
  })
}

// Global click listener
onMounted(() => document.addEventListener('click', handleClickOutside))
onUnmounted(() => document.removeEventListener('click', handleClickOutside))
</script>

<template>
  <div class="relative autocomplete-container w-full">
    <div class="relative">
      <Input
        ref="inputRef"
        v-model="searchQuery"
        :placeholder="placeholder"
        :disabled="disabled"
        @input="handleInput"
        @focus="handleFocus"
        @keydown="handleKeydown"
        class="pr-10"
        autocomplete="off"
      />
      <!-- Show logo in input if selected? No, text is fine. The dropdown shows logos. -->
      <div class="absolute right-3 top-2.5 text-muted-foreground pointer-events-none">
        <ChevronsUpDown class="h-4 w-4 opacity-50" />
      </div>
    </div>

    <div
      v-if="isOpen && filteredOptions.length > 0"
      ref="listRef"
      class="absolute z-50 mt-1 w-full overflow-auto rounded-md border bg-popover p-1 text-popover-foreground shadow-md max-h-60"
    >
      <div
        v-for="(option, index) in filteredOptions"
        :key="option.value"
        class="relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground data-[focused=true]:bg-accent data-[focused=true]:text-accent-foreground"
        :class="{ 'bg-accent text-accent-foreground': index === focusedIndex }"
        @click="selectOption(option)"
      >
        <img 
          v-if="option.image" 
          :src="option.image" 
          class="w-6 h-6 mr-2 object-contain" 
          alt=""
          loading="lazy"
        />
        <span class="flex-grow">{{ option.label }}</span>
        <Check
          v-if="option.value === modelValue"
          class="ml-2 h-4 w-4 opacity-100"
        />
      </div>
    </div>
    
    <div 
        v-if="isOpen && filteredOptions.length === 0 && searchQuery"
        class="absolute z-50 mt-1 w-full rounded-md border bg-popover p-4 shadow-md text-sm text-center text-muted-foreground"
    >
        No results found.
    </div>
  </div>
</template>
