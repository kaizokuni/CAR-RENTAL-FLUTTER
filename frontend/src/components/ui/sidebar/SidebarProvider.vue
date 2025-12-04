<script setup lang="ts">
import { type HTMLAttributes, provide, ref, computed } from 'vue'
import { cn } from '@/lib/utils'
import { TooltipProvider } from '@/components/ui/tooltip'
import {
  SIDEBAR_INJECTION_KEY,
  type SidebarState,
} from './context'

const props = withDefaults(defineProps<{
  defaultOpen?: boolean
  open?: boolean
  class?: HTMLAttributes['class']
}>(), {
  defaultOpen: true,
  open: undefined,
})

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'update:openMobile', value: boolean): void
}>()

const openState = ref(props.defaultOpen)
const open = computed({
  get: () => props.open ?? openState.value,
  set: (value) => {
    openState.value = value
    emit('update:open', value)
  },
})

const isMobile = ref(false) // Simplified
const openMobileState = ref(false)
const openMobile = computed({
  get: () => openMobileState.value,
  set: (value) => {
    openMobileState.value = value
    emit('update:openMobile', value)
  },
})

const state = computed<SidebarState>(() =>
  open.value ? 'expanded' : 'collapsed',
)

const toggleSidebar = () => {
  open.value = !open.value
}

provide(SIDEBAR_INJECTION_KEY, {
  state,
  open,
  isMobile,
  openMobile,
  toggleSidebar,
  setOpen: (value: boolean) => {
    open.value = value
  },
  setOpenMobile: (value: boolean) => {
    openMobile.value = value
  },
})
</script>

<template>
  <TooltipProvider :delay-duration="0">
    <div
      :style="{
        '--sidebar-width': '16rem',
        '--sidebar-width-icon': '3rem',
        '--sidebar-width-mobile': '18rem',
      }"
      :class="cn('group/sidebar-wrapper flex min-h-svh w-full has-[[data-variant=inset]]:bg-sidebar', props.class)"
    >
      <slot />
    </div>
  </TooltipProvider>
</template>
