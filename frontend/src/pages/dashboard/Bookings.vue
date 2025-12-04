<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-vue-next'
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Bookings</h1>
        <p class="text-muted-foreground">View and manage reservations.</p>
      </div>
      <Button>
        <Plus class="mr-2 h-4 w-4" />
        New Booking
      </Button>
    </div>
    
    <div class="border rounded-lg p-8 text-center text-muted-foreground bg-muted/10">
      No bookings yet.
    </div>
  </div>
</template>
