<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useFinancialsStore } from '@/stores/financials'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import { Plus, X } from 'lucide-vue-next'

const financialsStore = useFinancialsStore()
const isFormOpen = ref(false)
const form = ref({
    amount: 0,
    category: '',
    date: new Date().toISOString().split('T')[0],
    description: ''
})

onMounted(() => {
  financialsStore.fetchExpenses()
})

async function onSubmit() {
    try {
        await financialsStore.createExpense({
            ...form.value,
            date: new Date(form.value.date || '').toISOString()
        })
        isFormOpen.value = false
        form.value = {
            amount: 0,
            category: '',
            date: new Date().toISOString().split('T')[0],
            description: ''
        }
    } catch (e) {
        // Handled in store
    }
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold tracking-tight">Expenses</h1>
      <Button @click="isFormOpen = true">
        <Plus class="mr-2 h-4 w-4" /> Add Expense
      </Button>
    </div>

    <div v-if="financialsStore.isLoading" class="text-center py-10">
      Loading expenses...
    </div>

    <div v-else class="grid gap-4">
      <Card v-for="expense in financialsStore.expenses" :key="expense.id">
        <CardContent class="flex items-center justify-between p-6">
            <div>
                <div class="font-bold text-lg">{{ expense.category }}</div>
                <div class="text-sm text-muted-foreground">{{ expense.description }}</div>
                <div class="text-sm text-muted-foreground">{{ new Date(expense.date).toLocaleDateString() }}</div>
            </div>
            <div class="text-right">
                <div class="text-xl font-bold text-red-600">-${{ expense.amount.toFixed(2) }}</div>
            </div>
        </CardContent>
      </Card>
      
      <div v-if="financialsStore.expenses.length === 0" class="text-center py-10 text-muted-foreground">
        No expenses found.
      </div>
    </div>

    <div v-if="isFormOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="bg-background p-6 rounded-lg shadow-lg w-full max-w-md">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-bold">Add New Expense</h2>
                <Button variant="ghost" size="icon" @click="isFormOpen = false">
                    <X class="h-4 w-4" />
                </Button>
            </div>
            <form @submit.prevent="onSubmit" class="space-y-4">
                <div class="grid gap-2">
                    <Input id="category" v-model="form.category" placeholder="Maintenance, Fuel, etc." required />
                </div>
                <div class="grid gap-2">
                    <Label for="amount">Amount ($)</Label>
                    <Input id="amount" type="number" step="0.01" v-model="form.amount" required />
                </div>
                <div class="grid gap-2">
                    <Label for="date">Date</Label>
                    <Input id="date" type="date" v-model="form.date" required />
                </div>
                <div class="grid gap-2">
                    <Label for="desc">Description</Label>
                    <Input id="desc" v-model="form.description" />
                </div>
                <Button type="submit" class="w-full" :disabled="financialsStore.isLoading">Save Expense</Button>
            </form>
        </div>
    </div>
  </div>
</template>
