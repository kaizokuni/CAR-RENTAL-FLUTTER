<script setup lang="ts">
import { usePermissions } from '@/composables/usePermissions'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { UserPlus } from 'lucide-vue-next'

const { canAccess } = usePermissions()
</script>

<template>
  <div v-if="!canAccess(undefined, 'pro')" class="h-full">
    <UpgradeRequired 
      title="Staff Management" 
      description="Manage your team members, assign roles, and control access levels."
      required-plan="Pro"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Staff Management</h1>
        <p class="text-muted-foreground">Manage your team and their permissions.</p>
      </div>
      <Button>
        <UserPlus class="mr-2 h-4 w-4" />
        Add Staff Member
      </Button>
    </div>

    <Card>
      <CardHeader>
        <CardTitle>Team Members</CardTitle>
        <CardDescription>You have 1 active staff member.</CardDescription>
      </CardHeader>
      <CardContent>
        <div class="text-center py-8 text-muted-foreground">
          Staff list will appear here.
        </div>
      </CardContent>
    </Card>
  </div>
</template>
