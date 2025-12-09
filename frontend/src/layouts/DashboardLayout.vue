<script setup lang="ts">
import { onMounted } from 'vue'
import AppSidebar from '@/components/ui/sidebar/AppSidebar.vue'
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from '@/components/ui/sidebar'
import NotificationsPopover from '@/components/NotificationsPopover.vue'
import ThemeSwitcher from '@/components/ThemeSwitcher.vue'
import { useBrandingStore } from '@/stores/branding'

const brandingStore = useBrandingStore()

// Load branding on dashboard mount
onMounted(async () => {
  await brandingStore.fetchBranding()
})
</script>

<template>
  <SidebarProvider>
    <AppSidebar />
    <SidebarInset>
      <header class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-[[data-state=collapsed]]/sidebar-wrapper:h-12">
        <div class="flex items-center gap-2 px-4 w-full">
          <SidebarTrigger class="-ml-1" />
          <Separator orientation="vertical" class="mr-2 h-4" />
          <Breadcrumb>
            <BreadcrumbList>
              <BreadcrumbItem>
                <BreadcrumbPage>Dashboard</BreadcrumbPage>
              </BreadcrumbItem>
            </BreadcrumbList>
          </Breadcrumb>
          <div class="ml-auto flex items-center gap-2">
            <ThemeSwitcher />
            <NotificationsPopover />
          </div>
        </div>
      </header>
      <div class="flex flex-1 flex-col gap-4 p-4 pt-0">
        <router-view />
      </div>
    </SidebarInset>
  </SidebarProvider>
</template>
