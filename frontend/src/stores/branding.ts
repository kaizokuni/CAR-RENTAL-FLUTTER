import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'

export interface BrandingSettings {
  tenant_id: string
  logo_url: string
  primary_color: string
  secondary_color: string
  accent_color: string
  updated_at?: string
}

export const useBrandingStore = defineStore('branding', () => {
  const branding = ref<BrandingSettings>({
    tenant_id: '',
    logo_url: '',
    primary_color: '#3b82f6',
    secondary_color: '#10b981',
    accent_color: ''
  })
  const isLoading = ref(false)

  const authStore = useAuthStore()

  const getAuthHeaders = () => ({
    'Authorization': `Bearer ${authStore.token}`,
    'Content-Type': 'application/json'
  })

  const fetchBranding = async () => {
    isLoading.value = true
    try {
      const response = await fetch('/api/v1/branding', {
        headers: getAuthHeaders()
      })
      if (response.ok) {
        branding.value = await response.json()
        applyTheme()
      }
    } catch (e) {
      console.error('Failed to fetch branding:', e)
    } finally {
      isLoading.value = false
    }
  }

  const updateBranding = async (colors: { primary_color: string; secondary_color: string; accent_color: string }) => {
    const response = await fetch('/api/v1/branding', {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(colors)
    })
    if (!response.ok) throw new Error('Failed to update branding')
    branding.value = { ...branding.value, ...colors }
    applyTheme()
  }

  const updateLandingPage = async (settings: any) => {
    const response = await fetch('/api/v1/landing-page', {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(settings)
    })
    if (!response.ok) throw new Error('Failed to update landing page')
  }

  const uploadLogo = async (file: File) => {
    const formData = new FormData()
    formData.append('logo', file)

    const response = await fetch('/api/v1/branding/logo', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${authStore.token}` },
      body: formData
    })
    if (!response.ok) throw new Error('Failed to upload logo')
    const data = await response.json()
    branding.value.logo_url = data.logo_url
    return data
  }

  const applyTheme = () => {
    const root = document.documentElement
    if (branding.value.primary_color) {
      // Convert hex to HSL for shadcn compatibility
      const primary = hexToHsl(branding.value.primary_color)
      root.style.setProperty('--primary', primary)
    }
    if (branding.value.secondary_color) {
      const secondary = hexToHsl(branding.value.secondary_color)
      root.style.setProperty('--secondary', secondary)
    }
  }

  // Convert hex to HSL format (e.g., "221.2 83.2% 53.3%")
  const hexToHsl = (hex: string): string => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if (!result || !result[1] || !result[2] || !result[3]) return '221.2 83.2% 53.3%'
    
    const r = parseInt(result[1], 16) / 255
    const g = parseInt(result[2], 16) / 255
    const b = parseInt(result[3], 16) / 255

    const max = Math.max(r, g, b)
    const min = Math.min(r, g, b)
    let h = 0, s = 0
    const l = (max + min) / 2

    if (max !== min) {
      const d = max - min
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
      switch (max) {
        case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break
        case g: h = ((b - r) / d + 2) / 6; break
        case b: h = ((r - g) / d + 4) / 6; break
      }
    }

    return `${(h * 360).toFixed(1)} ${(s * 100).toFixed(1)}% ${(l * 100).toFixed(1)}%`
  }

  return {
    branding,
    isLoading,
    fetchBranding,
    updateBranding,
    updateLandingPage,
    uploadLogo,
    applyTheme
  }
})
