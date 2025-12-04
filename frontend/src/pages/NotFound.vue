<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Home, ArrowLeft } from 'lucide-vue-next'

const router = useRouter()

const goHome = () => {
  router.push('/dashboard')
}

const goBack = () => {
  router.back()
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-background p-4">
    <div class="mx-auto max-w-md text-center">
      <div class="mb-8">
        <h1 class="text-9xl font-bold text-primary">
          404
        </h1>
        <p class="mt-4 text-3xl font-semibold text-foreground">
          Page Not Found
        </p>
        <p class="mt-2 text-muted-foreground">
          Sorry, we couldn't find the page you're looking for.
        </p>
      </div>
      
      <div class="flex flex-col gap-3 sm:flex-row sm:justify-center">
        <Button @click="goBack" variant="outline" class="gap-2">
          <ArrowLeft class="h-4 w-4" />
          Go Back
        </Button>
        <Button @click="goHome" class="gap-2">
          <Home class="h-4 w-4" />
          Go to Dashboard
        </Button>
      </div>
    </div>
  </div>
</template>
