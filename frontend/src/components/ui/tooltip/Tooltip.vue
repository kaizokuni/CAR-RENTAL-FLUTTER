<script setup lang="ts">
import { TooltipRoot as Tooltip, type TooltipRootEmits, type TooltipRootProps, useForwardPropsEmits } from 'radix-vue'

const props = defineProps<TooltipRootProps>()
const emits = defineEmits<TooltipRootEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <Tooltip v-bind="forwarded">
    <slot />
  </Tooltip>
</template>
