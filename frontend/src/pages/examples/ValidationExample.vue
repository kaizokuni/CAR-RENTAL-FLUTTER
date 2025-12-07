<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useFormValidation, ValidationRules } from '@/composables/useFormValidation'
import { handleApiRequest } from '@/lib/errorHandler'
import { getApiEndpoint } from '@/config/env'
import ValidatedInput from '@/components/common/ValidatedInput.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const router = useRouter()
const { errors, validate, validateField } = useFormValidation()
const isLoading = ref(false)

// Form data
const formData = ref({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

// Validation rules
const rules = {
  name: [
    ValidationRules.required('Name'),
    ValidationRules.minLength(3, 'Name')
  ],
  email: [
    ValidationRules.required('Email'),
    ValidationRules.email()
  ],
  password: ValidationRules.password(),
  confirmPassword: [
    ValidationRules.required('Confirm Password'),
    {
      validate: (value: string) => value === formData.value.password,
      message: 'Passwords do not match'
    }
  ]
}

// Handle form submission
const handleSubmit = async () => {
  // Validate all fields
  if (!validate(formData.value, rules)) {
    return
  }

  isLoading.value = true

  // Use the unified error handler for API request
  const result = await handleApiRequest(
    () => fetch(getApiEndpoint('/api/v1/auth/register'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: formData.value.name,
        email: formData.value.email,
        password: formData.value.password
      })
    }),
    {
      successMessage: 'Account created successfully!',
      errorMessage: 'Failed to create account',
      showSuccessToast: true,
      showErrorToast: true,
      onSuccess: () => {
        router.push('/login')
      }
    }
  )

  isLoading.value = false
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-md">
      <CardHeader>
        <CardTitle>Create Account</CardTitle>
        <CardDescription>
          Example form using the unified validation system
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form @submit.prevent="handleSubmit" class="space-y-4">
          <!-- Using ValidatedInput component -->
          <ValidatedInput
            v-model="formData.name"
            label="Name"
            placeholder="John Doe"
            :error="errors.name"
            required
            @blur="validateField('name', formData.name, rules.name)"
          />

          <ValidatedInput
            v-model="formData.email"
            label="Email"
            type="email"
            placeholder="john@example.com"
            :error="errors.email"
            required
            @blur="validateField('email', formData.email, rules.email)"
          />

          <ValidatedInput
            v-model="formData.password"
            label="Password"
            type="password"
            placeholder="••••••••"
            :error="errors.password"
            required
            @blur="validateField('password', formData.password, rules.password)"
          >
            <template #hint>
              <p class="text-xs text-muted-foreground">
                Must be 8+ characters with uppercase, lowercase, and number
              </p>
            </template>
          </ValidatedInput>

          <ValidatedInput
            v-model="formData.confirmPassword"
            label="Confirm Password"
            type="password"
            placeholder="••••••••"
            :error="errors.confirmPassword"
            required
            @blur="validateField('confirmPassword', formData.confirmPassword, rules.confirmPassword)"
          />

          <Button type="submit" class="w-full" :disabled="isLoading">
            {{ isLoading ? 'Creating Account...' : 'Create Account' }}
          </Button>
        </form>
      </CardContent>
    </Card>
  </div>
</template>
