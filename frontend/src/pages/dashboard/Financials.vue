<script setup lang="ts">
import { usePermissions } from '@/composables/usePermissions'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const { canAccess } = usePermissions()
</script>

<template>
  <div v-if="!canAccess(undefined, 'pro')" class="h-full">
    <UpgradeRequired 
      title="Financial Reports" 
      description="Track revenue, expenses, and generate detailed financial statements."
      required-plan="Pro"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Financials</h1>
      <p class="text-muted-foreground">Overview of your business performance.</p>
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <Card>
        <CardHeader class="pb-2">
          <CardTitle class="text-sm font-medium">Total Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">$0.00</div>
          <p class="text-xs text-muted-foreground">+0% from last month</p>
        </CardContent>
      </Card>
      <!-- More cards... -->
    </div>
  </div>
</template>
