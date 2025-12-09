```vue
<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue'
import { Button } from "@/components/ui/button"
import {
  AlertCircle as LucideAlertCircle,
  Image as LucideImage,
  Upload as LucideUpload,
  X as LucideX,
  ArrowLeft,
  ArrowRight,
  Loader2,
  RefreshCw
} from "lucide-vue-next"
import { useAuthStore } from "@/stores/auth"
import { getApiEndpoint } from "@/config/env"
import { toast } from 'vue-sonner'

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

// -- State --
// Committed images (URLs from backend)
const images = ref<string[]>([...props.modelValue])

// Pending uploads (Local files waiting/uploading)
interface PendingUpload {
  id: string
  file: File
  previewUrl: string
  status: 'pending' | 'uploading' | 'error'
  error?: string
}
const pendingUploads = ref<PendingUpload[]>([])

const fileInputRef = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)

// Sync modelValue -> images (one-way, unless we just emitted)
watch(() => props.modelValue, (newVal) => {
  // Only sync if content is different to avoid fighting with local optimism if needed
  // For now, simple diff check or just replacement is fine as long as we append correctly
  if (JSON.stringify(newVal) !== JSON.stringify(images.value)) {
    images.value = [...newVal]
  }
}, { immediate: true })

// Cleanup previews on unmount
onUnmounted(() => {
  pendingUploads.value.forEach(u => URL.revokeObjectURL(u.previewUrl))
})

// -- Actions --

const processQueue = async () => {
  // Find next pending item
  const nextItem = pendingUploads.value.find(u => u.status === 'pending')
  if (!nextItem) return

  // Start upload
  nextItem.status = 'uploading'
  
  try {
    const url = await uploadFile(nextItem.file)
    if (url) {
      // Success: Remove from pending, add to real images
      removePending(nextItem.id) // This revokes URL too
      images.value.push(url)
      emit('update:modelValue', [...images.value])
    } else {
      throw new Error("No URL returned")
    }
  } catch (err: any) {
    nextItem.status = 'error'
    nextItem.error = err.message || 'Upload failed'
    // Don't remove, let user see error and retry/remove
  }

  // Process next
  await processQueue()
}

const uploadFile = async (file: File): Promise<string | null> => {
  const formData = new FormData()
  formData.append('image', file)

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
}

const handleFiles = (files: FileList | null) => {
  if (!files || files.length === 0) return

  const totalCurrent = images.value.length + pendingUploads.value.length
  const remainingSlots = props.maxImages - totalCurrent
  
  if (remainingSlots <= 0) {
    toast.error(`Maximum ${props.maxImages} images allowed`)
    return
  }

  const filesToAdd = Array.from(files).slice(0, remainingSlots)

  filesToAdd.forEach(file => {
    // Validate
    if (file.size > maxSize) {
      toast.error(`${file.name} is too large (max ${maxSizeMB}MB)`)
      return
    }
    if (!file.type.startsWith('image/')) {
      toast.error(`${file.name} is not an image`)
      return
    }

    // Add to pending
    pendingUploads.value.push({
      id: Math.random().toString(36).substring(7),
      file,
      previewUrl: URL.createObjectURL(file),
      status: 'pending'
    })
  })

  // Start processing
  processQueue()
  
  // Reset input
  if (fileInputRef.value) fileInputRef.value.value = ''
}

const removePending = (id: string) => {
  const idx = pendingUploads.value.findIndex(u => u.id === id)
  if (idx !== -1 && pendingUploads.value[idx]) {
    URL.revokeObjectURL(pendingUploads.value[idx].previewUrl)
    pendingUploads.value.splice(idx, 1)
  }
}

const retryUpload = (id: string) => {
  const item = pendingUploads.value.find(u => u.id === id)
  if (item) {
    item.status = 'pending'
    item.error = undefined
    processQueue()
  }
}

// -- Drag & Drop --
const onDrop = (e: DragEvent) => {
  isDragging.value = false
  const files = e.dataTransfer?.files
  if (files) handleFiles(files)
}

const onDragOver = (e: DragEvent) => {
  isDragging.value = true
}

const onDragLeave = (e: DragEvent) => {
  if (!(e.currentTarget as HTMLElement).contains(e.relatedTarget as Node)) {
    isDragging.value = false
  }
}

// -- Existing UI Helpers --
const openFileDialog = () => fileInputRef.value?.click()
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
const getImageUrl = (url: string) => {
  // Backend now returns absolute URLs, use them directly
  return url
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
      :class="{ 
        'justify-center': images.length === 0 && pendingUploads.length === 0, 
        'border-primary bg-primary/5 ring-2 ring-primary/20': isDragging 
      }"
      @dragover.prevent="onDragOver"
      @dragleave.prevent="onDragLeave"
      @drop.prevent="onDrop"
    >
      <!-- Combined Grid: Real Images + Pending Uploads -->
      <div v-if="images.length > 0 || pendingUploads.length > 0" class="flex w-full flex-col gap-3">
        <div class="flex items-center justify-between gap-2">
          <h3 class="truncate text-sm font-medium">
            Gallery ({{ images.length }} uploaded{{ pendingUploads.length ? `, ${pendingUploads.length} pending` : '' }})
          </h3>
          <Button
            variant="outline"
            type="button"
            @click="openFileDialog"
            :disabled="images.length + pendingUploads.length >= maxImages"
          >
            <LucideUpload class="-ms-0.5 size-3.5 opacity-60 mr-2" aria-hidden="true" />
            Add more
          </Button>
        </div>

        <div class="grid grid-cols-2 gap-4 md:grid-cols-3">
          
          <!-- Real Images -->
          <div
            v-for="(url, index) in images"
            :key="url"
            class="bg-accent relative aspect-square rounded-md overflow-hidden group border"
          >
            <!-- Cover Badge -->
            <div v-if="index === 0" class="absolute top-2 left-2 z-10 bg-yellow-400 text-black text-[10px] font-bold px-2 py-0.5 rounded-full shadow-sm">
              COVER
            </div>

            <img
              :src="getImageUrl(url)"
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

          <!-- Pending Uploads -->
          <div
            v-for="upload in pendingUploads"
            :key="upload.id"
            class="bg-accent relative aspect-square rounded-md overflow-hidden border border-dashed"
            :class="{ 'border-destructive/50 bg-destructive/5': upload.status === 'error' }"
          >
            <img
              :src="upload.previewUrl"
              class="size-full rounded-[inherit] object-cover opacity-60 grayscale"
            />
            
            <!-- Loading Overlay -->
            <div v-if="upload.status === 'uploading' || upload.status === 'pending'" class="absolute inset-0 flex items-center justify-center bg-black/10 backdrop-blur-[1px]">
               <div v-if="upload.status === 'uploading'" class="flex flex-col items-center gap-1">
                 <Loader2 class="h-6 w-6 animate-spin text-primary" />
                 <span class="text-[10px] font-medium text-white shadow-sm">Uploading...</span>
               </div>
               <div v-else class="flex flex-col items-center">
                 <span class="text-[10px] font-medium text-white/80">Waiting...</span>
               </div>
            </div>

            <!-- Error Overlay -->
            <div v-if="upload.status === 'error'" class="absolute inset-0 flex flex-col items-center justify-center p-2 text-center bg-destructive/10">
               <LucideAlertCircle class="h-6 w-6 text-destructive mb-1" />
               <span class="text-[10px] leading-tight text-destructive font-medium mb-2">{{ upload.error || 'Failed' }}</span>
               <div class="flex gap-1">
                 <Button size="icon" variant="outline" class="h-6 w-6" @click="retryUpload(upload.id)" title="Retry">
                   <RefreshCw class="h-3 w-3" />
                 </Button>
                 <Button size="icon" variant="destructive" class="h-6 w-6" @click="removePending(upload.id)" title="Remove">
                   <LucideX class="h-3 w-3" />
                 </Button>
               </div>
            </div>
          </div>

        </div>
      </div>

      <!-- Empty state -->
      <div v-else class="flex flex-col items-center justify-center px-4 py-3 text-center pointer-events-none">
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
          class="mt-4 pointer-events-auto" 
          @click="openFileDialog"
        >
          <LucideUpload class="-ms-1 size-4 opacity-60 mr-2" aria-hidden="true" />
          Select images
        </Button>
      </div>
    </div>

    <!-- Error display -->
    <!-- Removed global uploadError display as errors are now per pending item -->
  </div>
</template>
```
