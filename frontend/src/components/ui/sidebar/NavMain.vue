<script setup lang="ts">
import type { LucideIcon } from "lucide-vue-next"
import { ChevronRight, Lock } from "lucide-vue-next"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarMenuSub,
  SidebarMenuSubButton,
  SidebarMenuSubItem,
} from "@/components/ui/sidebar"
import { RouterLink } from 'vue-router'

defineProps<{
  items: {
    title: string
    url: string
    icon?: LucideIcon
    isActive?: boolean
    items?: {
      title: string
      url: string
    }[]
    badge?: string
    disabled?: boolean
    requiresSubscription?: string
  }[]
}>()
</script>

<template>
  <SidebarGroup>
    <SidebarGroupLabel>Menu</SidebarGroupLabel>
    <SidebarMenu>
      <template v-for="item in items" :key="item.title">
        <!-- Collapsible Item with Children -->
        <Collapsible
          v-if="item.items && item.items.length > 0"
          as-child
          :default-open="item.isActive"
          class="group/collapsible"
        >
          <SidebarMenuItem>
            <CollapsibleTrigger as-child>
              <SidebarMenuButton :tooltip="item.title" :disabled="item.disabled">
                <component :is="item.icon" v-if="item.icon" />
                <span>{{ item.title }}</span>
                
                <!-- Badge -->
                <span 
                  v-if="item.badge" 
                  class="ml-2 rounded-sm bg-primary/10 px-1.5 py-0.5 text-xs font-medium text-primary"
                >
                  {{ item.badge }}
                </span>

                <!-- Lock Icon if disabled -->
                <Lock v-if="item.disabled" class="ml-auto h-4 w-4 text-muted-foreground" />
                
                <!-- Chevron if has children -->
                <ChevronRight 
                  v-else 
                  class="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90" 
                />
              </SidebarMenuButton>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <SidebarMenuSub>
                <SidebarMenuSubItem v-for="subItem in item.items" :key="subItem.title">
                  <SidebarMenuSubButton as-child>
                    <RouterLink :to="subItem.url">
                      <span>{{ subItem.title }}</span>
                    </RouterLink>
                  </SidebarMenuSubButton>
                </SidebarMenuSubItem>
              </SidebarMenuSub>
            </CollapsibleContent>
          </SidebarMenuItem>
        </Collapsible>

        <!-- Single Item -->
        <SidebarMenuItem v-else>
          <SidebarMenuButton 
            as-child 
            :tooltip="item.title" 
            :disabled="item.disabled"
            :class="{ 'opacity-50 cursor-not-allowed': item.disabled }"
          >
            <div v-if="item.disabled" class="flex w-full items-center gap-2">
              <component :is="item.icon" v-if="item.icon" />
              <span>{{ item.title }}</span>
              <span 
                v-if="item.badge" 
                class="ml-2 rounded-sm bg-primary/10 px-1.5 py-0.5 text-xs font-medium text-primary"
              >
                {{ item.badge }}
              </span>
              <Lock class="ml-auto h-4 w-4 text-muted-foreground" />
            </div>
            <RouterLink v-else :to="item.url" class="flex w-full items-center gap-2">
              <component :is="item.icon" v-if="item.icon" />
              <span>{{ item.title }}</span>
              <span 
                v-if="item.badge" 
                class="ml-2 rounded-sm bg-primary/10 px-1.5 py-0.5 text-xs font-medium text-primary"
              >
                {{ item.badge }}
              </span>
            </RouterLink>
          </SidebarMenuButton>
        </SidebarMenuItem>
      </template>
    </SidebarMenu>
  </SidebarGroup>
</template>
