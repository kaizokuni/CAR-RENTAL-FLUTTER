<script setup lang="ts">
import { DialogRoot as Sheet, type DialogRootEmits as SheetEmits, type DialogRootProps as SheetProps, useForwardPropsEmits } from 'radix-vue'

const props = defineProps<SheetProps>()
const emits = defineEmits<SheetEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <Sheet v-bind="forwarded">
    <slot />
  </Sheet>
</template>
