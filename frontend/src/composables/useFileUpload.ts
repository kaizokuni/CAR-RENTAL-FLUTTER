import { ref, onMounted, onUnmounted, watch } from 'vue'

interface FileUploadOptions {
  accept?: string
  maxSize?: number
  multiple?: boolean
  maxFiles?: number
  initialFiles?: any[]
}

interface UploadedFile {
  id: string
  file: File | null
  name: string
  size: number
  type: string
  preview: string
  url?: string // For initial files
}

export function useFileUpload(options: FileUploadOptions = {}) {
  const files = ref<UploadedFile[]>([])
  const errors = ref<string[]>([])
  const inputRef = ref<HTMLInputElement | null>(null)
  const dropzoneRef = ref<HTMLElement | null>(null)

  // Initialize with passed files (normalized)
  if (options.initialFiles) {
    files.value = options.initialFiles.map(f => ({
      id: f.id || Math.random().toString(36).substring(7),
      file: null, // Initial files might not have File objects
      name: f.name || 'Existing Image',
      size: f.size || 0,
      type: f.type || 'image/jpeg',
      preview: f.url || '',
      url: f.url
    }))
  }

  const openFileDialog = () => {
    inputRef.value?.click()
  }

  const removeFile = (id: string) => {
    files.value = files.value.filter(f => f.id !== id)
  }

  const validateFile = (file: File): string | null => {
    if (options.maxSize && file.size > options.maxSize) {
      return `File ${file.name} is too large. Max size is ${Math.round(options.maxSize / 1024 / 1024)}MB.`
    }
    // Simple mime check if needed, but 'accept' on input handles most
    return null
  }

  const handleFiles = (fileList: FileList | null) => {
    if (!fileList) return

    errors.value = []
    const newFiles: UploadedFile[] = []
    
    // Check max files
    if (options.maxFiles && (files.value.length + fileList.length) > options.maxFiles) {
       errors.value.push(`Maximum ${options.maxFiles} files allowed.`)
       return
    }

    Array.from(fileList).forEach(file => {
      const error = validateFile(file)
      if (error) {
        errors.value.push(error)
        return
      }

      newFiles.push({
        id: Math.random().toString(36).substring(7),
        file,
        name: file.name,
        size: file.size,
        type: file.type,
        preview: URL.createObjectURL(file)
      })
    })

    if (options.multiple) {
      files.value = [...files.value, ...newFiles]
    } else {
      files.value = newFiles.slice(0, 1)
    }
  }

  const onDrop = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    dropzoneRef.value?.setAttribute('data-dragging', 'false')
    
    if (e.dataTransfer?.files) {
      handleFiles(e.dataTransfer.files)
    }
  }

  const onDragOver = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    dropzoneRef.value?.setAttribute('data-dragging', 'true')
  }

  const onDragLeave = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    dropzoneRef.value?.setAttribute('data-dragging', 'false')
  }

  const onInputChange = (e: Event) => {
    const target = e.target as HTMLInputElement
    handleFiles(target.files)
    // Reset input value to allow selecting same file again
    target.value = '' 
  }

  onMounted(() => {
    if (dropzoneRef.value) {
      dropzoneRef.value.addEventListener('dragover', onDragOver)
      dropzoneRef.value.addEventListener('dragleave', onDragLeave)
      dropzoneRef.value.addEventListener('drop', onDrop)
    }
    if (inputRef.value) {
      inputRef.value.type = 'file'
      inputRef.value.className = 'hidden' // Ensure it's hidden
      if (options.accept) inputRef.value.accept = options.accept
      if (options.multiple) inputRef.value.multiple = true
      inputRef.value.addEventListener('change', onInputChange)
    }
  })

  onUnmounted(() => {
     // Cleanup listeners
     // Cleanup object URLs
     files.value.forEach(f => {
       if (f.file) URL.revokeObjectURL(f.preview)
     })
  })

  return {
    files,
    errors,
    openFileDialog,
    removeFile,
    dropzoneRef,
    inputRef
  }
}
