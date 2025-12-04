<script setup lang="ts">
import type { SidebarProps } from "@/components/ui/sidebar"
import { computed } from "vue"
import { useAuthStore } from "@/stores/auth"
import { usePermissions } from "@/composables/usePermissions"
import { getSidebarConfig } from "@/config/sidebarConfig"
import { Building2 } from "lucide-vue-next"

import NavMain from "@/components/ui/sidebar/NavMain.vue"
import NavUser from "@/components/ui/sidebar/NavUser.vue"
import TeamSwitcher from "@/components/ui/sidebar/TeamSwitcher.vue"

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarRail,
} from "@/components/ui/sidebar"

const props = withDefaults(defineProps<SidebarProps>(), {
  collapsible: "icon",
})

const authStore = useAuthStore()
const { canAccess } = usePermissions()

const user = computed(() => {
  if (authStore.user) {
    return {
      name: `${authStore.user.first_name} ${authStore.user.last_name}`,
      email: authStore.user.email,
      avatar: "/avatars/admin.jpg",
    }
  }
  return {
    name: "User",
    email: "",
    avatar: "/avatars/admin.jpg",
  }
})

// Get sidebar config based on role
const sidebarConfig = computed(() => {
  const role = authStore.role || 'owner'
  return getSidebarConfig(role)
})

// Filter items based on permissions and subscription
const filteredNavItems = computed(() => {
  return sidebarConfig.value.sections.map(item => {
    // Check access
    const hasAccess = canAccess(item.requiresRole, item.requiresSubscription)
    
    return {
      title: item.label,
      url: item.path,
      icon: item.icon,
      isActive: false, // Logic for active state can be added if needed, usually handled by router-link
      items: item.children?.map(child => ({
        title: child.label,
        url: child.path
      })) || [],
      badge: item.badge,
      disabled: !hasAccess, // We might want to show them but disabled/locked
      requiresSubscription: item.requiresSubscription
    }
  })
})

const teams = [
  {
    name: "Car Rental Co.",
    logo: Building2,
    plan: "Enterprise",
  },
]
</script>

<template>
  <Sidebar v-bind="props">
    <SidebarHeader>
      <TeamSwitcher :teams="teams" />
    </SidebarHeader>
    <SidebarContent>
      <NavMain :items="filteredNavItems" />
    </SidebarContent>
    <SidebarFooter>
      <NavUser :user="user" />
    </SidebarFooter>
    <SidebarRail />
  </Sidebar>
</template>
