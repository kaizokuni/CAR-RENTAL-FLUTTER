<script setup lang="ts">
import { usePermissions } from '@/composables/usePermissions'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const { canAccess } = usePermissions()
</script>

<template>
  <div v-if="!canAccess(undefined, 'premium')" class="h-full">
    <UpgradeRequired 
      title="Custom Branding" 
      description="Customize your shop's look and feel with your own logo, colors, and domain."
      required-plan="Premium"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Branding & Customization</h1>
      <p class="text-muted-foreground">Make your car rental shop truly yours.</p>
    </div>

    <Card>
      <CardHeader>
        <CardTitle>Brand Identity</CardTitle>
        <CardDescription>Upload your logo and set your brand colors.</CardDescription>
      </CardHeader>
      <CardContent class="space-y-4">
        <div class="grid gap-2">
          <Label>Logo</Label>
          <div class="border-2 border-dashed rounded-lg p-8 text-center text-muted-foreground">
            Upload Logo
          </div>
        </div>
        <div class="grid gap-2">
          <Label>Primary Color</Label>
          <div class="flex gap-2">
            <Input type="color" class="w-12 h-10 p-1" value="#000000" />
            <Input value="#000000" />
          </div>
        </div>
        <Button>Save Changes</Button>
      </CardContent>
    </Card>
  </div>
</template>
