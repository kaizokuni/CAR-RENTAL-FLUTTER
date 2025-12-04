<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/stores/auth'
import { jwtDecode } from 'jwt-decode'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const email = ref('')
const password = ref('')

// Check for impersonation token
onMounted(() => {
  const token = route.query.token as string
  if (token) {
    // Save token and redirect
    localStorage.setItem('token', token)
    
    // Decode to get role
    try {
      const decoded: any = jwtDecode(token)
      const role = decoded.role
      
      if (role === 'super_admin') {
        router.push('/dashboard/admin/dashboard')
      } else {
        router.push('/dashboard')
      }
    } catch (e) {
      console.error('Failed to decode token', e)
      router.push('/dashboard')
    }
  }
})

const handleLogin = async () => {
  try {
    await authStore.login({
      email: email.value,
      password: password.value
    })
  } catch (e) {
    // Error is handled in the store and displayed in the template
  }
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-muted/40 p-4">
    <Card class="mx-auto max-w-sm w-full">
      <CardHeader>
        <CardTitle class="text-2xl">
          Login
        </CardTitle>
        <CardDescription>
          Enter your email below to login to your account
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form @submit.prevent="handleLogin">
          <div class="grid gap-4">
            <div class="grid gap-2">
              <Label for="email">Email</Label>
              <Input
                id="email"
                v-model="email"
                type="email"
                placeholder="m@example.com"
                required
                :disabled="authStore.isLoading"
              />
            </div>
            <div class="grid gap-2">
              <div class="flex items-center">
                <Label for="password">Password</Label>
                <a
                  href="#"
                  class="ml-auto inline-block text-sm underline"
                >
                  Forgot your password?
                </a>
              </div>
              <Input
                id="password"
                v-model="password"
                type="password"
                required
                :disabled="authStore.isLoading"
              />
            </div>
            
            <div v-if="authStore.error" class="text-sm text-destructive">
              {{ authStore.error }}
            </div>

            <Button type="submit" class="w-full" :disabled="authStore.isLoading">
              <span v-if="authStore.isLoading">Logging in...</span>
              <span v-else>Login</span>
            </Button>
            <Button variant="outline" class="w-full" type="button">
              Login with Google
            </Button>
          </div>
          <div class="mt-4 text-center text-sm">
            Don't have an account?
            <a href="/signup" class="underline">
              Sign up
            </a>
          </div>
        </form>
      </CardContent>
    </Card>
  </div>
</template>
