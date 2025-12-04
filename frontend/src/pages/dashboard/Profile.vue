<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'

const authStore = useAuthStore()
</script>

<template>
  <div class="p-6 space-y-6">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Settings</h1>
      <p class="text-muted-foreground">Manage your account and preferences.</p>
    </div>
    
    <Card>
      <CardHeader>
        <CardTitle>Profile Information</CardTitle>
        <CardDescription>Update your personal details.</CardDescription>
      </CardHeader>
      <CardContent class="space-y-4">
        <div class="grid gap-2">
          <Label>Email</Label>
          <Input :value="authStore.user?.email" disabled />
        </div>
        <div class="grid gap-2">
          <Label>First Name</Label>
          <Input :value="authStore.user?.first_name" />
        </div>
        <div class="grid gap-2">
          <Label>Last Name</Label>
          <Input :value="authStore.user?.last_name" />
        </div>
        <Button>Save Changes</Button>
      </CardContent>
    </Card>
  </div>
</template>
