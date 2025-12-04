import { inject, type ComputedRef, type Ref } from 'vue'

export type SidebarState = 'expanded' | 'collapsed'

export interface SidebarContext {
  state: ComputedRef<SidebarState>
  open: Ref<boolean>
  isMobile: Ref<boolean>
  openMobile: Ref<boolean>
  toggleSidebar: () => void
  setOpen?: (value: boolean) => void
  setOpenMobile?: (value: boolean) => void
}

export const SIDEBAR_INJECTION_KEY = Symbol('sidebar')

export function useSidebar() {
  const context = inject<SidebarContext>(SIDEBAR_INJECTION_KEY)
  if (!context) {
    throw new Error('useSidebar must be used within a SidebarProvider.')
  }
  return context
}
