<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { Lock } from 'lucide-vue-next'

defineProps<{
  title: string
  description: string
  requiredPlan: 'Pro' | 'Premium'
}>()
</script>

<template>
  <div class="flex flex-col items-center justify-center min-h-[60vh] text-center p-8 space-y-6">
    <div class="bg-muted p-4 rounded-full">
      <Lock class="w-12 h-12 text-muted-foreground" />
    </div>
    
    <div class="space-y-2 max-w-md">
      <h2 class="text-2xl font-bold tracking-tight">{{ title }}</h2>
      <p class="text-muted-foreground">{{ description }}</p>
    </div>

    <div class="bg-primary/5 border border-primary/20 rounded-lg p-4 w-full max-w-sm">
      <p class="text-sm font-medium text-primary mb-1">
        Requires {{ requiredPlan }} Plan
      </p>
      <p class="text-xs text-muted-foreground">
        Upgrade your subscription to unlock this feature and more.
      </p>
    </div>

    <Button size="lg" class="w-full max-w-xs">
      Upgrade to {{ requiredPlan }}
    </Button>
  </div>
</template>
