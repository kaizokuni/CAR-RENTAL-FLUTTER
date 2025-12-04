<script setup lang="ts">
import { CollapsibleRoot as Collapsible, type CollapsibleRootEmits, type CollapsibleRootProps, useForwardPropsEmits } from 'radix-vue'

const props = defineProps<CollapsibleRootProps>()
const emits = defineEmits<CollapsibleRootEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <Collapsible v-bind="forwarded">
    <slot />
  </Collapsible>
</template>
