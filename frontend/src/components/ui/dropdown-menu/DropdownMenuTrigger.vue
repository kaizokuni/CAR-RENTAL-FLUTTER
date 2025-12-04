<script setup lang="ts">
import { DropdownMenuTrigger, type DropdownMenuTriggerProps } from 'radix-vue'
import { cn } from '@/lib/utils'

const props = defineProps<DropdownMenuTriggerProps & { class?: string }>()
</script>

<template>
  <DropdownMenuTrigger v-bind="props" :class="cn(props.class)">
    <slot />
  </DropdownMenuTrigger>
</template>
