<script setup lang="ts">
import type { Component } from "vue"

import { ChevronsUpDown, Plus, Building2 } from "lucide-vue-next"
import { ref, watch } from "vue"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuShortcut,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

import {
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar"

interface Team {
  name: string
  logo?: string | null  // Image URL
  logoIcon?: Component  // Fallback icon
  plan: string
}

const props = defineProps<{
  teams: Team[]
}>()

const { isMobile } = useSidebar()

// Default team
const defaultTeam: Team = { name: 'My Organization', plan: 'Standard' }
const activeTeam = ref<Team>(props.teams[0] || defaultTeam)

// Watch for changes in teams prop
watch(() => props.teams, (newTeams) => {
  if (newTeams && newTeams.length > 0 && newTeams[0]) {
    activeTeam.value = newTeams[0]
  }
}, { deep: true })
</script>

<template>
  <SidebarMenu>
    <SidebarMenuItem>
      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <SidebarMenuButton
            size="lg"
            class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
            v-if="activeTeam"
          >
            <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground overflow-hidden">
              <img 
                v-if="activeTeam.logo" 
                :src="activeTeam.logo" 
                :alt="activeTeam.name"
                class="size-6 object-contain"
              />
              <component 
                v-else 
                :is="activeTeam.logoIcon || Building2" 
                class="size-4" 
              />
            </div>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">
                {{ activeTeam.name }}
              </span>
              <span class="truncate text-xs">{{ activeTeam.plan }}</span>
            </div>
            <ChevronsUpDown class="ml-auto" />
          </SidebarMenuButton>
        </DropdownMenuTrigger>
        <DropdownMenuContent
          class="w-[--reka-dropdown-menu-trigger-width] min-w-56 rounded-lg"
          align="start"
          :side="isMobile ? 'bottom' : 'right'"
          :side-offset="4"
        >
          <DropdownMenuLabel class="text-xs text-muted-foreground">
            Organization
          </DropdownMenuLabel>
          <DropdownMenuItem
            v-for="(team, index) in teams"
            :key="team.name"
            class="gap-2 p-2"
            @click="activeTeam = team"
          >
            <div class="flex size-6 items-center justify-center rounded-sm border overflow-hidden">
              <img 
                v-if="team.logo" 
                :src="team.logo" 
                :alt="team.name"
                class="size-4 object-contain"
              />
              <component 
                v-else 
                :is="team.logoIcon || Building2" 
                class="size-3.5 shrink-0" 
              />
            </div>
            {{ team.name }}
            <DropdownMenuShortcut>⌘{{ index + 1 }}</DropdownMenuShortcut>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </SidebarMenuItem>
  </SidebarMenu>
</template>
