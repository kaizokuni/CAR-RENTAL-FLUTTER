<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Home, Shield } from 'lucide-vue-next'

const router = useRouter()

const goHome = () => {
  router.push('/dashboard')
}

const goToLogin = () => {
  router.push('/login')
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-background p-4">
    <div class="mx-auto max-w-md text-center">
      <div class="mb-8">
        <div class="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-destructive/10">
          <Shield class="h-10 w-10 text-destructive" />
        </div>
        <h1 class="text-6xl font-bold text-destructive">
          403
        </h1>
        <p class="mt-4 text-3xl font-semibold text-foreground">
          Access Denied
        </p>
        <p class="mt-2 text-muted-foreground">
          You don't have permission to access this resource.
        </p>
      </div>
      
      <div class="flex flex-col gap-3 sm:flex-row sm:justify-center">
        <Button @click="goToLogin" variant="outline">
          Login
        </Button>
        <Button @click="goHome" class="gap-2">
          <Home class="h-4 w-4" />
          Go to Dashboard
        </Button>
      </div>
    </div>
  </div>
</template>
