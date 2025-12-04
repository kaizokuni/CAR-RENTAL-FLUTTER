<script setup lang="ts">
import { onMounted } from 'vue'
import { useReportsStore } from '@/stores/reports'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { BarChart, Activity } from 'lucide-vue-next'

const reportsStore = useReportsStore()

onMounted(() => {
  reportsStore.fetchUtilization()
  reportsStore.fetchRevenueByCar()
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="text-2xl font-bold tracking-tight">Reports & Analytics</h1>

    <div v-if="reportsStore.isLoading" class="text-center py-10">
      Loading reports...
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2">
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Activity class="h-5 w-5" />
            Fleet Utilization (Last 7 Days)
          </CardTitle>
          <CardDescription>Percentage of fleet rented out daily</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="h-[200px] flex items-end justify-between gap-2 pt-4">
            <div 
                v-for="stat in reportsStore.utilization" 
                :key="stat.date" 
                class="flex flex-col items-center gap-1 flex-1"
            >
                <div 
                    class="w-full bg-primary/80 rounded-t-md transition-all hover:bg-primary"
                    :style="{ height: `${stat.percentage}%` }"
                ></div>
                <span class="text-[10px] text-muted-foreground rotate-45 origin-left translate-y-2">{{ new Date(stat.date).toLocaleDateString(undefined, {weekday: 'short'}) }}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <BarChart class="h-5 w-5" />
            Top Revenue Cars
          </CardTitle>
          <CardDescription>Highest earning vehicles</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="space-y-4">
            <div v-for="(car, index) in reportsStore.revenueByCar" :key="car.car_id" class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="flex h-8 w-8 items-center justify-center rounded-full bg-muted font-bold text-xs">
                        {{ index + 1 }}
                    </div>
                    <div>
                        <div class="font-medium text-sm">{{ car.make }} {{ car.model }}</div>
                        <div class="text-xs text-muted-foreground">{{ car.booking_count }} bookings</div>
                    </div>
                </div>
                <div class="font-bold text-sm">
                    ${{ car.total_revenue.toFixed(2) }}
                </div>
            </div>
            <div v-if="reportsStore.revenueByCar.length === 0" class="text-center text-muted-foreground py-4">
                No data available.
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
