<script setup lang="ts">
import { ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const name = ref('')
const email = ref('')
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')

// Initialize form with user data
if (authStore.user) {
  name.value = `${authStore.user.first_name} ${authStore.user.last_name}`
  email.value = authStore.user.email
}

const handleUpdateProfile = () => {
  // TODO: Implement profile update
  console.log('Update profile', { name: name.value, email: email.value })
}

const handleChangePassword = () => {
  if (newPassword.value !== confirmPassword.value) {
    alert('Passwords do not match')
    return
  }
  // TODO: Implement password change
  console.log('Change password')
}
</script>

<template>
  <div class="flex flex-1 flex-col gap-4 p-4 pt-0">
    <div class="flex items-center justify-between">
      <h1 class="text-3xl font-bold">
        Profile
      </h1>
    </div>

    <div class="grid gap-6 md:grid-cols-2">
      <!-- Profile Information -->
      <Card>
        <CardHeader>
          <CardTitle>Profile Information</CardTitle>
          <CardDescription>
            Update your personal information
         </CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="handleUpdateProfile" class="space-y-4">
            <div class="flex justify-center mb-6">
              <Avatar class="h-24 w-24">
                <AvatarImage src="/avatars/admin.jpg" alt="Profile" />
                <AvatarFallback class="text-2xl">AU</AvatarFallback>
              </Avatar>
            </div>

            <div class="space-y-2">
              <Label for="name">Name</Label>
              <Input
                id="name"
                v-model="name"
                type="text"
                placeholder="Your name"
              />
            </div>

            <div class="space-y-2">
              <Label for="email">Email</Label>
              <Input
                id="email"
                v-model="email"
                type="email"
                placeholder="your.email@example.com"
              />
            </div>

            <Button type="submit" class="w-full">
              Save Changes
            </Button>
          </form>
        </CardContent>
      </Card>

      <!-- Change Password -->
      <Card>
        <CardHeader>
          <CardTitle>Change Password</CardTitle>
          <CardDescription>
            Update your password to keep your account secure
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="handleChangePassword" class="space-y-4">
            <div class="space-y-2">
              <Label for="current-password">Current Password</Label>
              <Input
                id="current-password"
                v-model="currentPassword"
                type="password"
                placeholder="Enter current password"
              />
            </div>

            <div class="space-y-2">
              <Label for="new-password">New Password</Label>
              <Input
                id="new-password"
                v-model="newPassword"
                type="password"
                placeholder="Enter new password"
              />
            </div>

            <div class="space-y-2">
              <Label for="confirm-password">Confirm Password</Label>
              <Input
                id="confirm-password"
                v-model="confirmPassword"
                type="password"
                placeholder="Confirm new password"
              />
            </div>

            <Button type="submit" class="w-full">
              Change Password
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  </div>
</template>
