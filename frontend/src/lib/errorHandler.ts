import { toast } from 'vue-sonner'

/**
 * Parse backend error messages and convert to user-friendly format
 */
export function parseBackendError(errorMessage: string): string {
  if (!errorMessage) return 'An error occurred'
  
  // Handle Gin validation errors: "Key: 'Request.Field' Error:Field validation for 'Field' failed on the 'tag' tag"
  const validationMatch = errorMessage.match(/Field validation for '(\w+)' failed on the '(\w+)' tag/)
  
  if (validationMatch && validationMatch.length >= 3) {
    const field = validationMatch[1]!.replace(/([A-Z])/g, ' $1').trim()
    const rule = validationMatch[2]!
    
    switch (rule) {
      case 'required':
        return `${field} is required`
      case 'min':
        return `${field} is too short`
      case 'max':
        return `${field} is too long`
      case 'email':
        return 'Please enter a valid email address'
      case 'oneof':
        return `${field} has an invalid value`
      default:
        return `${field} validation failed`
    }
  }

  return errorMessage
}

/**
 * Unified error handler for API requests
 * Handles both success and error cases with toast notifications
 */
export async function handleApiRequest<T>(
  request: () => Promise<Response>,
  options: {
    successMessage?: string
    errorMessage?: string
    onSuccess?: (data: T) => void
    onError?: (error: string) => void
    showSuccessToast?: boolean
    showErrorToast?: boolean
  } = {}
): Promise<{ success: boolean; data?: T; error?: string }> {
  const {
    successMessage = 'Operation completed successfully',
    errorMessage = 'Operation failed',
    onSuccess,
    onError,
    showSuccessToast = true,
    showErrorToast = true
  } = options

  try {
    const response = await request()
    const data = await response.json()

    if (!response.ok) {
      const parsedError = parseBackendError(data.error || errorMessage)
      
      if (showErrorToast) {
        toast.error('Error', {
          description: parsedError
        })
      }

      if (onError) {
        onError(parsedError)
      }

      return { success: false, error: parsedError }
    }

    if (showSuccessToast) {
      toast.success('Success', {
        description: successMessage
      })
    }

    if (onSuccess) {
      onSuccess(data)
    }

    return { success: true, data }
  } catch (error: any) {
    const errorMsg = error.message || 'An unexpected error occurred'
    
    if (showErrorToast) {
      toast.error('Error', {
        description: errorMsg
      })
    }

    if (onError) {
      onError(errorMsg)
    }

    return { success: false, error: errorMsg }
  }
}

/**
 * Show a success toast notification
 */
export function showSuccess(message: string, description?: string) {
  toast.success(message, description ? { description } : undefined)
}

/**
 * Show an error toast notification
 */
export function showError(message: string, description?: string) {
  toast.error(message, description ? { description } : undefined)
}

/**
 * Show an info toast notification
 */
export function showInfo(message: string, description?: string) {
  toast.info(message, description ? { description } : undefined)
}

/**
 * Show a warning toast notification
 */
export function showWarning(message: string, description?: string) {
  toast.warning(message, description ? { description } : undefined)
}
