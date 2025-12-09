<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useBrandingStore } from '@/stores/branding'
import { usePermissions } from '@/composables/usePermissions'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Upload, Palette, Check, Image as ImageIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const { canAccess } = usePermissions()
const brandingStore = useBrandingStore()

const primaryColor = ref('#3b82f6')
const secondaryColor = ref('#10b981')
const accentColor = ref('')
const isUploading = ref(false)
const isSaving = ref(false)
const logoPreview = ref<string | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)

// Suggested colors extracted from logo
const suggestedColors = ref<string[]>([])

onMounted(async () => {
  await brandingStore.fetchBranding()
  primaryColor.value = brandingStore.branding.primary_color || '#3b82f6'
  secondaryColor.value = brandingStore.branding.secondary_color || '#10b981'
  accentColor.value = brandingStore.branding.accent_color || ''
  if (brandingStore.branding.logo_url) {
    logoPreview.value = brandingStore.branding.logo_url
  }
})

const handleLogoUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || !files.length) return

  const file = files[0]
  if (!file || !file.type.startsWith('image/')) {
    toast.error('Please upload an image file')
    return
  }

  isUploading.value = true
  try {
    // Show preview
    const reader = new FileReader()
    reader.onload = (e) => {
      const result = e.target?.result as string
      logoPreview.value = result
      // Extract colors from image
      if (result) extractColors(result)
    }
    reader.readAsDataURL(file)

    // Upload to server
    await brandingStore.uploadLogo(file)
    toast.success('Logo uploaded successfully!')
  } catch (e) {
    toast.error('Failed to upload logo')
  } finally {
    isUploading.value = false
  }
}

const extractColors = (imageData: string) => {
  // Simple color extraction - get dominant colors
  const img = new Image()
  img.onload = () => {
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    canvas.width = img.width
    canvas.height = img.height
    ctx.drawImage(img, 0, 0)

    const data = ctx.getImageData(0, 0, canvas.width, canvas.height)
    const colors = getTopColors(data.data)
    suggestedColors.value = colors
  }
  img.src = imageData
}

const getTopColors = (data: Uint8ClampedArray): string[] => {
  const colorMap = new Map<string, number>()
  
  for (let i = 0; i < data.length; i += 4) {
    const r = Math.round((data[i] ?? 0) / 32) * 32
    const g = Math.round((data[i + 1] ?? 0) / 32) * 32
    const b = Math.round((data[i + 2] ?? 0) / 32) * 32
    
    // Skip very light or very dark colors
    const brightness = (r + g + b) / 3
    if (brightness < 30 || brightness > 225) continue
    
    const hex = rgbToHex(r, g, b)
    colorMap.set(hex, (colorMap.get(hex) || 0) + 1)
  }

  // Sort by frequency and get top 5
  return [...colorMap.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([color]) => color)
}

const rgbToHex = (r: number, g: number, b: number): string => {
  return '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('')
}

const applySuggestedColor = (color: string, type: 'primary' | 'secondary') => {
  if (type === 'primary') {
    primaryColor.value = color
  } else {
    secondaryColor.value = color
  }
}

const saveColors = async () => {
  isSaving.value = true
  try {
    await brandingStore.updateBranding({
      primary_color: primaryColor.value,
      secondary_color: secondaryColor.value,
      accent_color: accentColor.value
    })
    toast.success('Branding colors saved!')
  } catch (e) {
    toast.error('Failed to save colors')
  } finally {
    isSaving.value = false
  }
}

const triggerFileInput = () => {
  fileInput.value?.click()
}
</script>

<template>
  <div v-if="!canAccess(undefined, 'premium')" class="h-full">
    <UpgradeRequired 
      title="Brand Customization" 
      description="Customize your brand colors, upload your logo, and create a unique identity for your car rental business."
      required-plan="Premium"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Brand Customization</h1>
      <p class="text-muted-foreground">Personalize your dashboard with your brand colors and logo.</p>
    </div>

    <div class="grid gap-6 md:grid-cols-2">
      <!-- Logo Upload -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <ImageIcon class="h-5 w-5" />
            Logo Upload
          </CardTitle>
          <CardDescription>Upload your company logo (PNG, JPG, SVG)</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            class="hidden"
            @change="handleLogoUpload"
          />
          
          <div 
            class="border-2 border-dashed rounded-lg p-8 text-center cursor-pointer hover:border-primary/50 transition-colors"
            @click="triggerFileInput"
          >
            <div v-if="logoPreview" class="flex flex-col items-center gap-4">
              <img 
                :src="logoPreview" 
                alt="Logo preview" 
                class="max-h-32 max-w-full object-contain"
              />
              <p class="text-sm text-muted-foreground">Click to change logo</p>
            </div>
            <div v-else class="flex flex-col items-center gap-2">
              <Upload class="h-10 w-10 text-muted-foreground" />
              <p class="text-sm text-muted-foreground">Click to upload your logo</p>
            </div>
          </div>

          <!-- Suggested Colors -->
          <div v-if="suggestedColors.length > 0" class="space-y-2">
            <Label>Suggested colors from logo:</Label>
            <div class="flex gap-2 flex-wrap">
              <button
                v-for="color in suggestedColors"
                :key="color"
                class="w-8 h-8 rounded-full border-2 border-white shadow-md hover:scale-110 transition-transform"
                :style="{ backgroundColor: color }"
                @click="applySuggestedColor(color, 'primary')"
                :title="`Use ${color} as primary`"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Color Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Palette class="h-5 w-5" />
            Brand Colors
          </CardTitle>
          <CardDescription>Choose your primary and secondary brand colors</CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
          <!-- Primary Color -->
          <div class="space-y-2">
            <Label>Primary Color</Label>
            <div class="flex items-center gap-3">
              <input
                type="color"
                v-model="primaryColor"
                class="w-12 h-10 rounded cursor-pointer border-0"
              />
              <Input v-model="primaryColor" class="flex-1 font-mono uppercase" maxlength="7" />
            </div>
          </div>

          <!-- Secondary Color -->
          <div class="space-y-2">
            <Label>Secondary Color</Label>
            <div class="flex items-center gap-3">
              <input
                type="color"
                v-model="secondaryColor"
                class="w-12 h-10 rounded cursor-pointer border-0"
              />
              <Input v-model="secondaryColor" class="flex-1 font-mono uppercase" maxlength="7" />
            </div>
          </div>

          <!-- Preview -->
          <div class="space-y-2">
            <Label>Preview</Label>
            <div class="flex gap-2">
              <Button :style="{ backgroundColor: primaryColor }" class="text-white">
                Primary Button
              </Button>
              <Button :style="{ backgroundColor: secondaryColor }" class="text-white">
                Secondary
              </Button>
            </div>
          </div>

          <Button @click="saveColors" :disabled="isSaving" class="w-full">
            <Check class="mr-2 h-4 w-4" />
            {{ isSaving ? 'Saving...' : 'Save Colors' }}
          </Button>
        </CardContent>
      </Card>
    </div>

    <!-- Live Preview Section -->
    <Card>
      <CardHeader>
        <CardTitle>Live Preview</CardTitle>
        <CardDescription>See how your branding looks across the interface</CardDescription>
      </CardHeader>
      <CardContent>
        <div class="border rounded-lg p-4 space-y-4" :style="{ borderColor: primaryColor }">
          <div class="flex items-center gap-3">
            <img 
              v-if="logoPreview" 
              :src="logoPreview" 
              alt="Logo" 
              class="h-10 object-contain"
            />
            <span class="font-bold text-lg" :style="{ color: primaryColor }">Your Brand Name</span>
          </div>
          <div class="flex gap-2">
            <div class="px-3 py-1 rounded-full text-white text-sm" :style="{ backgroundColor: primaryColor }">Available</div>
            <div class="px-3 py-1 rounded-full text-white text-sm" :style="{ backgroundColor: secondaryColor }">Active</div>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
