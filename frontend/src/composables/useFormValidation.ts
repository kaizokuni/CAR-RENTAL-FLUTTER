import { ref, type Ref } from 'vue'
import { toast } from 'vue-sonner'

export interface ValidationRule {
  validate: (value: any) => boolean
  message: string
}

export interface FieldRules {
  [key: string]: ValidationRule[]
}

export interface FieldErrors {
  [key: string]: string
}

/**
 * Reusable validation composable for form validation
 * 
 * @example
 * const { errors, validate, validateField, clearError, hasErrors } = useFormValidation()
 * 
 * const rules = {
 *   email: [
 *     { validate: (v) => !!v, message: 'Email is required' },
 *     { validate: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), message: 'Invalid email' }
 *   ]
 * }
 * 
 * validateField('email', emailValue, rules.email)
 */
export function useFormValidation() {
  const errors: Ref<FieldErrors> = ref({})

  /**
   * Validate a single field
   */
  const validateField = (fieldName: string, value: any, rules: ValidationRule[]): boolean => {
    if (!rules || rules.length === 0) {
      errors.value[fieldName] = ''
      return true
    }

    for (const rule of rules) {
      if (!rule.validate(value)) {
        errors.value[fieldName] = rule.message
        return false
      }
    }

    errors.value[fieldName] = ''
    return true
  }

  /**
   * Validate all fields at once
   */
  const validate = (formData: { [key: string]: any }, rules: FieldRules): boolean => {
    let isValid = true

    for (const fieldName in rules) {
      const fieldValue = formData[fieldName]
      const fieldRules = rules[fieldName]
      
      if (fieldRules && !validateField(fieldName, fieldValue, fieldRules)) {
        isValid = false
      }
    }

    return isValid
  }

  /**
   * Clear error for a specific field
   */
  const clearError = (fieldName: string) => {
    errors.value[fieldName] = ''
  }

  /**
   * Clear all errors
   */
  const clearAllErrors = () => {
    errors.value = {}
  }

  /**
   * Check if there are any errors
   */
  const hasErrors = (): boolean => {
    return Object.values(errors.value).some(error => error !== '')
  }

  /**
   * Show validation error toast
   */
  const showValidationError = (message: string = 'Please fix validation errors') => {
    toast.error('Validation Error', {
      description: message
    })
  }

  return {
    errors,
    validate,
    validateField,
    clearError,
    clearAllErrors,
    hasErrors,
    showValidationError
  }
}

/**
 * Common validation rules that can be reused
 */
export const ValidationRules = {
  required: (fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: any) => {
      if (typeof value === 'string') return value.trim().length > 0
      return value !== null && value !== undefined && value !== ''
    },
    message: `${fieldName} is required`
  }),

  minLength: (length: number, fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: string) => !value || value.length >= length,
    message: `${fieldName} must be at least ${length} characters`
  }),

  maxLength: (length: number, fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: string) => !value || value.length <= length,
    message: `${fieldName} must be at most ${length} characters`
  }),

  email: (fieldName: string = 'Email'): ValidationRule => ({
    validate: (value: string) => !value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
    message: `Please enter a valid ${fieldName.toLowerCase()}`
  }),

  pattern: (regex: RegExp, message: string): ValidationRule => ({
    validate: (value: string) => !value || regex.test(value),
    message
  }),

  number: (fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: any) => !value || !isNaN(Number(value)),
    message: `${fieldName} must be a number`
  }),

  min: (minValue: number, fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: any) => !value || Number(value) >= minValue,
    message: `${fieldName} must be at least ${minValue}`
  }),

  max: (maxValue: number, fieldName: string = 'This field'): ValidationRule => ({
    validate: (value: any) => !value || Number(value) <= maxValue,
    message: `${fieldName} must be at most ${maxValue}`
  }),

  password: (fieldName: string = 'Password'): ValidationRule[] => [
    ValidationRules.required(fieldName),
    ValidationRules.minLength(8, fieldName),
    {
      validate: (value: string) => !value || /[A-Z]/.test(value),
      message: `${fieldName} must contain at least one uppercase letter`
    },
    {
      validate: (value: string) => !value || /[a-z]/.test(value),
      message: `${fieldName} must contain at least one lowercase letter`
    },
    {
      validate: (value: string) => !value || /[0-9]/.test(value),
      message: `${fieldName} must contain at least one number`
    }
  ],

  subdomain: (fieldName: string = 'Subdomain'): ValidationRule[] => [
    ValidationRules.required(fieldName),
    ValidationRules.minLength(3, fieldName),
    {
      validate: (value: string) => !value || /^[a-z0-9-]+$/.test(value),
      message: `${fieldName} can only contain lowercase letters, numbers, and hyphens`
    },
    {
      validate: (value: string) => !value || (!value.startsWith('-') && !value.endsWith('-')),
      message: `${fieldName} cannot start or end with a hyphen`
    }
  ]
}
