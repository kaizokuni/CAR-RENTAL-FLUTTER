<script setup lang="ts">
import { DialogTrigger as SheetTrigger, type DialogTriggerProps as SheetTriggerProps } from 'radix-vue'

const props = defineProps<SheetTriggerProps>()
</script>

<template>
  <SheetTrigger v-bind="props">
    <slot />
  </SheetTrigger>
</template>
