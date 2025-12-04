<script setup lang="ts">
import { AvatarRoot as Avatar, type AvatarRootProps as AvatarProps } from 'radix-vue'
import { cn } from '@/lib/utils'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<AvatarProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})
</script>

<template>
  <Avatar
    v-bind="delegatedProps"
    :class="cn('relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full', props.class)"
  >
    <slot />
  </Avatar>
</template>
