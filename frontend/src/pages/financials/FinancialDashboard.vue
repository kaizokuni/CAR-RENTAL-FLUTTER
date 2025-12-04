<script setup lang="ts">
import { onMounted } from 'vue'
import { useFinancialsStore } from '@/stores/financials'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { DollarSign, TrendingUp, TrendingDown, FileText } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'

const financialsStore = useFinancialsStore()

onMounted(() => {
  financialsStore.fetchStats()
  financialsStore.fetchExpenses() // Pre-fetch for recent list
  financialsStore.fetchInvoices() // Pre-fetch for recent list
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="text-2xl font-bold tracking-tight">Financial Overview</h1>

    <div v-if="financialsStore.isLoading && !financialsStore.stats" class="text-center py-10">
      Loading financials...
    </div>

    <div v-else class="grid gap-4 md:grid-cols-3">
      <Card>
        <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle class="text-sm font-medium">Total Revenue</CardTitle>
          <DollarSign class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">${{ financialsStore.stats?.total_revenue.toFixed(2) || '0.00' }}</div>
          <p class="text-xs text-muted-foreground">From all invoices</p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle class="text-sm font-medium">Total Expenses</CardTitle>
          <TrendingDown class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">${{ financialsStore.stats?.total_expenses.toFixed(2) || '0.00' }}</div>
          <p class="text-xs text-muted-foreground">Operational costs</p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle class="text-sm font-medium">Net Profit</CardTitle>
          <TrendingUp class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold" :class="{'text-green-600': (financialsStore.stats?.net_profit || 0) >= 0, 'text-red-600': (financialsStore.stats?.net_profit || 0) < 0}">
            ${{ financialsStore.stats?.net_profit.toFixed(2) || '0.00' }}
          </div>
          <p class="text-xs text-muted-foreground">Revenue - Expenses</p>
        </CardContent>
      </Card>
    </div>

    <div class="grid gap-4 md:grid-cols-2 mt-4">
        <Card>
            <CardHeader>
                <CardTitle>Recent Invoices</CardTitle>
            </CardHeader>
            <CardContent>
                <div class="space-y-2">
                    <div v-for="invoice in financialsStore.invoices.slice(0, 5)" :key="invoice.id" class="flex justify-between items-center text-sm border-b pb-2">
                        <div>
                            <div class="font-medium">{{ invoice.customer_name || 'Unknown Customer' }}</div>
                            <div class="text-xs text-muted-foreground">{{ new Date(invoice.issued_date).toLocaleDateString() }}</div>
                        </div>
                        <div class="flex items-center gap-2">
                             <span class="text-xs px-2 py-1 rounded bg-secondary">{{ invoice.status }}</span>
                             <span class="font-bold">${{ invoice.amount.toFixed(2) }}</span>
                        </div>
                    </div>
                    <div v-if="financialsStore.invoices.length === 0" class="text-center text-muted-foreground py-4">No invoices found.</div>
                </div>
                <div class="mt-4">
                    <Button variant="outline" class="w-full" as-child>
                        <router-link to="/dashboard/financials/invoices">View All Invoices</router-link>
                    </Button>
                </div>
            </CardContent>
        </Card>

        <Card>
            <CardHeader>
                <CardTitle>Recent Expenses</CardTitle>
            </CardHeader>
            <CardContent>
                <div class="space-y-2">
                    <div v-for="expense in financialsStore.expenses.slice(0, 5)" :key="expense.id" class="flex justify-between items-center text-sm border-b pb-2">
                        <div>
                            <div class="font-medium">{{ expense.category }}</div>
                            <div class="text-xs text-muted-foreground">{{ new Date(expense.date).toLocaleDateString() }}</div>
                        </div>
                        <span class="font-bold text-red-600">-${{ expense.amount.toFixed(2) }}</span>
                    </div>
                    <div v-if="financialsStore.expenses.length === 0" class="text-center text-muted-foreground py-4">No expenses found.</div>
                </div>
                <div class="mt-4">
                    <Button variant="outline" class="w-full" as-child>
                        <router-link to="/dashboard/financials/expenses">View All Expenses</router-link>
                    </Button>
                </div>
            </CardContent>
        </Card>
    </div>
  </div>
</template>
