<script setup lang="ts">
import { onMounted } from 'vue'
import { useNotificationsStore } from '@/stores/notifications'
import { Button } from '@/components/ui/button'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import { Bell } from 'lucide-vue-next'

const notificationsStore = useNotificationsStore()

onMounted(() => {
  notificationsStore.fetchNotifications()
  // Poll every minute
  setInterval(() => {
    notificationsStore.fetchNotifications()
  }, 60000)
})
</script>

<template>
  <Popover>
    <PopoverTrigger as-child>
      <Button variant="ghost" size="icon" class="relative">
        <Bell class="h-5 w-5" />
        <span v-if="notificationsStore.unreadCount > 0" class="absolute top-0 right-0 h-2 w-2 rounded-full bg-red-600" />
        <span class="sr-only">Notifications</span>
      </Button>
    </PopoverTrigger>
    <PopoverContent class="w-80 p-0" align="end">
      <div class="p-4 font-medium border-b">Notifications</div>
      <div class="max-h-[300px] overflow-y-auto">
        <div v-if="notificationsStore.notifications.length === 0" class="p-4 text-center text-sm text-muted-foreground">
          No notifications.
        </div>
        <div
          v-for="notification in notificationsStore.notifications"
          :key="notification.id"
          class="p-4 border-b last:border-0 hover:bg-muted/50 cursor-pointer transition-colors"
          :class="{ 'bg-muted/20': !notification.is_read }"
          @click="notificationsStore.markAsRead(notification.id)"
        >
          <div class="flex items-start gap-2">
            <div class="flex-1 space-y-1">
              <p class="text-sm font-medium leading-none">
                {{ notification.title }}
              </p>
              <p class="text-xs text-muted-foreground">
                {{ notification.message }}
              </p>
              <p class="text-[10px] text-muted-foreground pt-1">
                {{ new Date(notification.created_at).toLocaleTimeString() }}
              </p>
            </div>
            <div v-if="!notification.is_read" class="h-2 w-2 rounded-full bg-blue-600 mt-1" />
          </div>
        </div>
      </div>
    </PopoverContent>
  </Popover>
</template>
