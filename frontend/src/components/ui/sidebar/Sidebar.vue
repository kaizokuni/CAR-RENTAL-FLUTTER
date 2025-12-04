<script setup lang="ts">
import { computed, type HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { useSidebar } from './context'

export type SidebarSide = 'left' | 'right'
export type SidebarVariant = 'sidebar' | 'floating' | 'inset'
export type SidebarCollapsible = 'offcanvas' | 'icon' | 'none'

export interface SidebarProps {
  side?: SidebarSide
  variant?: SidebarVariant
  collapsible?: SidebarCollapsible
  class?: HTMLAttributes['class']
}

const props = withDefaults(defineProps<SidebarProps>(), {
  side: 'left',
  variant: 'sidebar',
  collapsible: 'offcanvas',
})

const { state } = useSidebar()

const widthClass = computed(() => {
  if (props.collapsible === 'none') {
    return 'w-[--sidebar-width]'
  }
  return state.value === 'expanded'
    ? 'w-[--sidebar-width]'
    : 'w-[--sidebar-width-icon]'
})

const variantClass = computed(() => {
  if (props.variant === 'floating') {
    return 'm-2 rounded-2xl border shadow-lg'
  }
  if (props.variant === 'inset') {
    return 'm-2 rounded-2xl border'
  }
  return ''
})
</script>

<template>
  <aside
    data-sidebar="sidebar"
    :data-state="state"
    :data-variant="props.variant"
    :data-side="props.side"
    :data-collapsible="props.collapsible"
    :class="cn(
      'peer group flex h-svh shrink-0 flex-col gap-2 border-border bg-sidebar text-sidebar-foreground transition-[width] ease-linear',
      'data-[side=left]:border-r data-[side=right]:border-l',
      variantClass,
      widthClass,
      props.class,
    )"
  >
    <slot />
  </aside>
</template>
