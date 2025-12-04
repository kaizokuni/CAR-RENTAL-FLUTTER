<script setup lang="ts">
import { onMounted } from 'vue'
import { useFinancialsStore } from '@/stores/financials'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const financialsStore = useFinancialsStore()

onMounted(() => {
  financialsStore.fetchInvoices()
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="text-2xl font-bold tracking-tight">Invoices</h1>

    <div v-if="financialsStore.isLoading" class="text-center py-10">
      Loading invoices...
    </div>

    <div v-else class="grid gap-4">
      <Card v-for="invoice in financialsStore.invoices" :key="invoice.id">
        <CardContent class="flex items-center justify-between p-6">
            <div>
                <div class="font-bold text-lg">{{ invoice.customer_name || 'Customer' }}</div>
                <div class="text-sm text-muted-foreground">Issued: {{ new Date(invoice.issued_date).toLocaleDateString() }}</div>
                <div class="text-sm text-muted-foreground">Due: {{ invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : 'N/A' }}</div>
            </div>
            <div class="text-right">
                <div class="text-xl font-bold">${{ invoice.amount.toFixed(2) }}</div>
                <div class="text-sm px-2 py-1 rounded bg-secondary inline-block mt-1">{{ invoice.status }}</div>
            </div>
        </CardContent>
      </Card>
      
      <div v-if="financialsStore.invoices.length === 0" class="text-center py-10 text-muted-foreground">
        No invoices found.
      </div>
    </div>
  </div>
</template>
