<script setup lang="ts">
import { type HTMLAttributes, computed } from 'vue'
import {
  PopoverRoot,
  type PopoverRootEmits,
  type PopoverRootProps,
  useForwardPropsEmits,
} from 'radix-vue'

const props = defineProps<PopoverRootProps>()
const emits = defineEmits<PopoverRootEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <PopoverRoot v-bind="forwarded">
    <slot />
  </PopoverRoot>
</template>
