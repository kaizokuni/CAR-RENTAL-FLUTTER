<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-muted/40 p-4">
    <Card class="w-full max-w-md">
      <CardHeader class="text-center">
        <div class="flex justify-center mb-4">
          <div class="size-12 rounded-full bg-primary flex items-center justify-center">
            <span class="text-primary-foreground font-bold text-xl">CR</span>
          </div>
        </div>
        <CardTitle class="text-2xl">
          Partner with Us
        </CardTitle>
        <CardDescription>
          Start your car rental business today
        </CardDescription>
      </CardHeader>
      <CardContent class="space-y-4 text-center">
        <p class="text-muted-foreground">
          We are currently accepting new car rental partners by invitation only.
        </p>
        <p class="text-sm">
          To open your shop on our platform, please contact our sales team to get your dedicated workspace and subdomain.
        </p>
        
        <div class="mt-6 p-4 bg-muted rounded-lg">
          <h3 class="font-semibold mb-2">Contact Us</h3>
          <p class="text-sm text-muted-foreground">Email: sales@carrental.com</p>
          <p class="text-sm text-muted-foreground">Phone: +1 (555) 123-4567</p>
        </div>

        <div class="mt-6">
          <Button as-child class="w-full">
            <a href="/login">Back to Login</a>
          </Button>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
