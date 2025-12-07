<script setup lang="ts">
import { ref, watch } from 'vue'
import { Button } from "@/components/ui/button"
import {
  AlertCircle as LucideAlertCircle,
  Image as LucideImage,
  Upload as LucideUpload,
  X as LucideX,
  ArrowLeft,
  ArrowRight,
} from "lucide-vue-next"
import { useAuthStore } from "@/stores/auth"
import { getApiEndpoint } from "@/config/env"

interface Props {
  modelValue: string[]
  maxImages?: number
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  maxImages: 10
})

const emit = defineEmits<{
  'update:modelValue': [value: string[]]
}>()

const authStore = useAuthStore()
const API_URL = getApiEndpoint('/api/v1')

const maxSizeMB = 5
const maxSize = maxSizeMB * 1024 * 1024

// Local state for images (URLs)
const images = ref<string[]>([...props.modelValue])
const isUploading = ref(false)
const uploadError = ref('')
const fileInputRef = ref<HTMLInputElement | null>(null)

// Sync from parent
watch(() => props.modelValue, (newVal) => {
  images.value = [...newVal]
}, { immediate: true })

// Upload a single file to the backend
const uploadFile = async (file: File): Promise<string | null> => {
  const formData = new FormData()
  formData.append('image', file)

  try {
    const response = await fetch(`${API_URL}/cars/upload-image`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authStore.token}`
      },
      body: formData
    })

    if (!response.ok) {
      const data = await response.json()
      throw new Error(data.error || 'Upload failed')
    }

    const data = await response.json()
    return data.url
  } catch (error: any) {
    console.error('Upload error:', error)
    uploadError.value = error.message
    return null
  }
}

// Handle file selection
const handleFiles = async (files: FileList | null) => {
  if (!files || files.length === 0) return
  
  uploadError.value = ''
  isUploading.value = true

  const remainingSlots = props.maxImages - images.value.length
  const filesToUpload = Array.from(files).slice(0, remainingSlots)

  for (const file of filesToUpload) {
    // Validate size
    if (file.size > maxSize) {
      uploadError.value = `${file.name} is too large (max ${maxSizeMB}MB)`
      continue
    }

    // Validate type
    if (!file.type.startsWith('image/')) {
      uploadError.value = `${file.name} is not an image`
      continue
    }

    const url = await uploadFile(file)
    if (url) {
      images.value.push(url)
    }
  }

  isUploading.value = false
  emit('update:modelValue', [...images.value])
  
  // Reset file input
  if (fileInputRef.value) {
    fileInputRef.value.value = ''
  }
}

const openFileDialog = () => {
  fileInputRef.value?.click()
}

const removeImage = (index: number) => {
  images.value.splice(index, 1)
  emit('update:modelValue', [...images.value])
}

const moveLeft = (index: number) => {
  if (index > 0) {
    const temp = images.value[index]!
    images.value.splice(index, 1)
    images.value.splice(index - 1, 0, temp)
    emit('update:modelValue', [...images.value])
  }
}

const moveRight = (index: number) => {
  if (index < images.value.length - 1) {
    const temp = images.value[index]!
    images.value.splice(index, 1)
    images.value.splice(index + 1, 0, temp)
    emit('update:modelValue', [...images.value])
  }
}
</script>

<template>
  <div class="flex flex-col gap-2">
    <!-- Hidden file input -->
    <input 
      ref="fileInputRef"
      type="file"
      accept="image/*"
      multiple
      class="hidden"
      @change="handleFiles(($event.target as HTMLInputElement).files)"
    />

    <!-- Drop area / Image grid -->
    <div
      class="border-input relative flex min-h-52 flex-col items-center overflow-hidden rounded-xl border border-dashed p-4 transition-colors"
      :class="{ 'justify-center': images.length === 0 }"
    >
      <!-- Images grid -->
      <div v-if="images.length > 0" class="flex w-full flex-col gap-3">
        <div class="flex items-center justify-between gap-2">
          <h3 class="truncate text-sm font-medium">
            Uploaded Files ({{ images.length }})
          </h3>
          <Button
            variant="outline"
            type="button"
            @click="openFileDialog"
            :disabled="images.length >= maxImages || isUploading"
          >
            <LucideUpload class="-ms-0.5 size-3.5 opacity-60 mr-2" aria-hidden="true" />
            {{ isUploading ? 'Uploading...' : 'Add more' }}
          </Button>
        </div>

        <div class="grid grid-cols-2 gap-4 md:grid-cols-3">
          <div
            v-for="(url, index) in images"
            :key="url"
            class="bg-accent relative aspect-square rounded-md overflow-hidden group"
          >
            <!-- Cover Badge -->
            <div v-if="index === 0" class="absolute top-2 left-2 z-10 bg-yellow-400 text-black text-[10px] font-bold px-2 py-0.5 rounded-full shadow-sm">
              COVER
            </div>

            <img
              :src="url.startsWith('/') ? getApiEndpoint(url) : url"
              alt="Car image"
              class="size-full rounded-[inherit] object-cover transition-transform group-hover:scale-105"
            />
            
            <!-- Remove Button -->
            <Button
              @click="removeImage(index)"
              size="icon"
              type="button"
              class="absolute top-2 right-2 size-6 rounded-full bg-destructive text-white hover:bg-destructive/90 shadow-sm opacity-0 group-hover:opacity-100 transition-opacity"
              aria-label="Remove image"
            >
              <LucideX class="size-3.5" />
            </Button>
            
            <!-- Reorder Controls -->
            <div class="absolute bottom-2 inset-x-2 flex justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
              <Button 
                v-if="index > 0"
                size="icon"
                type="button"
                variant="secondary"
                class="h-6 w-6 rounded-full shadow-sm"
                @click="moveLeft(index)"
                title="Move Left"
              >
                <ArrowLeft class="h-3 w-3" />
              </Button>
              <Button 
                v-if="index < images.length - 1"
                size="icon"
                type="button"
                variant="secondary"
                class="h-6 w-6 rounded-full shadow-sm"
                @click="moveRight(index)"
                title="Move Right"
              >
                <ArrowRight class="h-3 w-3" />
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else class="flex flex-col items-center justify-center px-4 py-3 text-center">
        <div
          class="bg-background mb-2 flex size-11 shrink-0 items-center justify-center rounded-full border"
          aria-hidden="true"
        >
          <LucideImage class="size-4 opacity-60" />
        </div>
        <p class="mb-1.5 text-sm font-medium">Drop your images here</p>
        <p class="text-muted-foreground text-xs">
          SVG, PNG, JPG or GIF (max. {{ maxSizeMB }}MB)
        </p>
        <Button 
          variant="outline" 
          type="button" 
          class="mt-4" 
          @click="openFileDialog"
          :disabled="isUploading"
        >
          <LucideUpload class="-ms-1 size-4 opacity-60 mr-2" aria-hidden="true" />
          {{ isUploading ? 'Uploading...' : 'Select images' }}
        </Button>
      </div>
    </div>

    <!-- Error display -->
    <div
      v-if="uploadError"
      class="text-destructive flex items-center gap-1 text-xs"
      role="alert"
    >
      <LucideAlertCircle class="size-3 shrink-0" />
      <span>{{ uploadError }}</span>
    </div>
  </div>
</template>
