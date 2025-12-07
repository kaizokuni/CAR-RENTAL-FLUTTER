<script setup lang="ts">
import { ref, computed } from 'vue'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Upload, X, AlertCircle, ImageIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

interface Props {
  modelValue: File[]
  error?: string
  maxFiles?: number
  maxSizeMB?: number
  disabled?: boolean
  required?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  error: '',
  maxFiles: 5,
  maxSizeMB: 5,
  disabled: false,
  required: false
})

const emit = defineEmits<{
  'update:modelValue': [files: File[]]
  'blur': []
}>()

const isDragging = ref(false)
const previews = ref<{ file: File; url: string }[]>([])

// Generate preview URLs for selected files
const generatePreviews = (files: File[]) => {
  previews.value = files.map(file => ({
    file,
    url: URL.createObjectURL(file)
  }))
}

// Initialize previews if modelValue is provided
if (props.modelValue.length > 0) {
  generatePreviews(props.modelValue)
}

const validateFile = (file: File): string | null => {
  if (!file.type.startsWith('image/')) {
    return 'Only image files are allowed'
  }
  
  const maxSize = props.maxSizeMB * 1024 * 1024
  if (file.size > maxSize) {
    return `Image must be less than ${props.maxSizeMB}MB`
  }
  
  return null
}

const handleFiles = (files: FileList | null) => {
  if (!files) return
  
  const newFiles = Array.from(files)
  const currentFiles = props.modelValue
  
  // Check max files limit
  if (currentFiles.length + newFiles.length > props.maxFiles) {
    toast.error('Too many files', {
      description: `Maximum ${props.maxFiles} images allowed`
    })
    return
  }
  
  // Validate all files
  for (const file of newFiles) {
    const error = validateFile(file)
    if (error) {
      toast.error('Invalid file', {
        description: `${file.name}: ${error}`
      })
      return
    }
  }
  
  const updatedFiles = [...currentFiles, ...newFiles]
  emit('update:modelValue', updatedFiles)
  generatePreviews(updatedFiles)
}

const removeFile = (index: number) => {
  const updatedFiles = props.modelValue.filter((_, i) => i !== index)
  emit('update:modelValue', updatedFiles)
  generatePreviews(updatedFiles)
  
  // Revoke old preview URL
  if (previews.value[index]) {
    URL.revokeObjectURL(previews.value[index].url)
  }
}

const handleDrop = (e: DragEvent) => {
  isDragging.value = false
  handleFiles(e.dataTransfer?.files || null)
}

const handleInputChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  handleFiles(target.files)
  // Reset input so same file can be selected again
  target.value = ''
}

const hasError = computed(() => !!props.error)
const canAddMore = computed(() => props.modelValue.length < props.maxFiles)
</script>

<template>
  <div class="grid gap-2">
    <Label :class="hasError ? 'text-destructive' : ''">
      Vehicle Images <span v-if="required" class="text-destructive">*</span>
    </Label>
    
    <!-- Upload Area -->
    <div
      v-if="canAddMore"
      class="relative border-2 border-dashed rounded-lg p-8 text-center transition-colors"
      :class="[
        isDragging ? 'border-primary bg-primary/5' : 'border-muted-foreground/25',
        hasError ? 'border-destructive' : '',
        disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer hover:border-primary/50'
      ]"
      @dragover.prevent="isDragging = true"
      @dragleave.prevent="isDragging = false"
      @drop.prevent="handleDrop"
      @click="!disabled && ($refs.fileInput as HTMLInputElement)?.click()"
    >
      <input
        ref="fileInput"
        type="file"
        accept="image/*"
        multiple
        class="hidden"
        :disabled="disabled"
        @change="handleInputChange"
      />
      
      <div class="flex flex-col items-center gap-2">
        <div class="p-3 rounded-full bg-muted">
          <Upload class="h-6 w-6 text-muted-foreground" />
        </div>
        <div>
          <p class="font-medium">
            {{ isDragging ? 'Drop images here' : 'Click to upload or drag and drop' }}
          </p>
          <p class="text-sm text-muted-foreground mt-1">
            PNG, JPG up to {{ maxSizeMB }}MB (max {{ maxFiles }} images)
          </p>
        </div>
      </div>
      
      <AlertCircle v-if="hasError" class="absolute top-2 right-2 h-5 w-5 text-destructive" />
    </div>
    
    <!-- Preview Grid -->
    <div v-if="previews.length > 0" class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-2">
      <div
        v-for="(preview, index) in previews"
        :key="index"
        class="relative group aspect-video rounded-lg overflow-hidden border bg-muted"
      >
        <img
          :src="preview.url"
          :alt="`Preview ${index + 1}`"
          class="w-full h-full object-cover"
        />
        <div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
          <Button
            size="icon"
            variant="destructive"
            class="h-8 w-8"
            @click.stop="removeFile(index)"
            :disabled="disabled"
          >
            <X class="h-4 w-4" />
          </Button>
        </div>
        <div class="absolute top-2 left-2 bg-black/70 text-white text-xs px-2 py-1 rounded">
          {{ index + 1 }} / {{ maxFiles }}
        </div>
      </div>
    </div>
    
    <p v-if="hasError" class="text-sm text-destructive flex items-center gap-1">
      {{ error }}
    </p>
    <p v-else-if="previews.length > 0" class="text-xs text-muted-foreground">
      {{ previews.length }} / {{ maxFiles }} images selected
    </p>
  </div>
</template>
