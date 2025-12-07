<script setup lang="ts">
import { ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Copy, Check, Eye, EyeOff } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Card, CardContent } from '@/components/ui/card'

interface Props {
  open: boolean
  shopName: string
  subdomain: string
  adminEmail: string
  adminPassword: string
  subscriptionTier: string
  paymentMethod: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  'continue': []
}>()

const showPassword = ref(false)
const copiedItems = ref<Record<string, boolean>>({})

const copyToClipboard = async (text: string, label: string) => {
  try {
    await navigator.clipboard.writeText(text)
    copiedItems.value[label] = true
    toast.success(`${label} copied!`)
    
    setTimeout(() => {
      copiedItems.value[label] = false
    }, 2000)
  } catch (err) {
    toast.error('Failed to copy')
  }
}

const copyAllCredentials = async () => {
  const credentials = `
Shop Name: ${props.shopName}
Subdomain: ${props.subdomain}
Admin Email: ${props.adminEmail}
Admin Password: ${props.adminPassword}
Subscription: ${props.subscriptionTier}
Payment Method: ${props.paymentMethod}
  `.trim()
  
  await copyToClipboard(credentials, 'All credentials')
}

const handleContinue = () => {
  emit('update:open', false)
  emit('continue')
}
</script>

<template>
  <Dialog :open="open" @update:open="emit('update:open', $event)">
    <DialogContent class="sm:max-w-[600px]">
      <DialogHeader>
        <DialogTitle class="text-2xl flex items-center gap-2">
          🎉 Shop Created Successfully!
        </DialogTitle>
        <DialogDescription>
          Share these credentials with the shop owner for admin portal access.
        </DialogDescription>
      </DialogHeader>

      <Card class="border-2 border-primary/20 bg-primary/5">
        <CardContent class="pt-6">
          <div class="space-y-4">
            <!-- Shop Name -->
            <div class="flex items-start justify-between gap-4 p-3 rounded-lg bg-background/80 border">
              <div class="flex-1 min-w-0">
                <p class="text-xs text-muted-foreground mb-1">Shop Name</p>
                <p class="font-semibold text-lg truncate">{{ shopName }}</p>
              </div>
              <Button
                size="icon"
                variant="ghost"
                class="flex-shrink-0"
                @click="copyToClipboard(shopName, 'Shop name')"
              >
                <Check v-if="copiedItems['Shop name']" class="h-4 w-4 text-green-600" />
                <Copy v-else class="h-4 w-4" />
              </Button>
            </div>

            <!-- Admin Portal URL -->
            <div class="flex items-start justify-between gap-4 p-3 rounded-lg bg-background/80 border">
              <div class="flex-1 min-w-0">
                <p class="text-xs text-muted-foreground mb-1">Admin Portal URL</p>
                <p class="font-mono text-sm text-primary break-all">{{ subdomain }}.localhost:5173</p>
              </div>
              <Button
                size="icon"
                variant="ghost"
                class="flex-shrink-0"
                @click="copyToClipboard(`${subdomain}.localhost:5173`, 'Portal URL')"
              >
                <Check v-if="copiedItems['Portal URL']" class="h-4 w-4 text-green-600" />
                <Copy v-else class="h-4 w-4" />
              </Button>
            </div>

            <!-- Admin Email -->
            <div class="flex items-start justify-between gap-4 p-3 rounded-lg bg-background/80 border">
              <div class="flex-1 min-w-0">
                <p class="text-xs text-muted-foreground mb-1">Admin Email</p>
                <p class="font-medium break-all">{{ adminEmail }}</p>
              </div>
              <Button
                size="icon"
                variant="ghost"
                class="flex-shrink-0"
                @click="copyToClipboard(adminEmail, 'Email')"
              >
                <Check v-if="copiedItems['Email']" class="h-4 w-4 text-green-600" />
                <Copy v-else class="h-4 w-4" />
              </Button>
            </div>

            <!-- Admin Password -->
            <div class="flex items-start justify-between gap-4 p-3 rounded-lg bg-background/80 border">
              <div class="flex-1 min-w-0">
                <p class="text-xs text-muted-foreground mb-1">Admin Password</p>
                <div class="flex items-center gap-2">
                  <p class="font-mono font-semibold">
                    {{ showPassword ? adminPassword : '••••••••••' }}
                  </p>
                  <Button
                    size="icon"
                    variant="ghost"
                    class="h-6 w-6"
                    @click="showPassword = !showPassword"
                  >
                    <EyeOff v-if="showPassword" class="h-3 w-3" />
                    <Eye v-else class="h-3 w-3" />
                  </Button>
                </div>
              </div>
              <Button
                size="icon"
                variant="ghost"
                class="flex-shrink-0"
                @click="copyToClipboard(adminPassword, 'Password')"
              >
                <Check v-if="copiedItems['Password']" class="h-4 w-4 text-green-600" />
                <Copy v-else class="h-4 w-4" />
              </Button>
            </div>

            <!-- Subscription & Payment -->
            <div class="grid grid-cols-2 gap-3">
              <div class="p-3 rounded-lg bg-background/80 border">
                <p class="text-xs text-muted-foreground mb-1">Subscription Tier</p>
                <p class="font-semibold capitalize">{{ subscriptionTier }}</p>
              </div>
              <div class="p-3 rounded-lg bg-background/80 border">
                <p class="text-xs text-muted-foreground mb-1">Payment Method</p>
                <p class="font-semibold capitalize">{{ paymentMethod }}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <DialogFooter class="flex-col sm:flex-row gap-2">
        <Button variant="outline" @click="copyAllCredentials" class="w-full sm:w-auto">
          <Copy class="mr-2 h-4 w-4" />
          Copy All Credentials
        </Button>
        <Button @click="handleContinue" class="w-full sm:w-auto">
          Continue to Dashboard
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
