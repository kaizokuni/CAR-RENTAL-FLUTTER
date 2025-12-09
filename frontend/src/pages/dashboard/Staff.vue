<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useStaffStore, type StaffMember, type CreateStaffData } from '@/stores/staff'
import { usePermissions } from '@/composables/usePermissions'
import UpgradeRequired from '@/components/UpgradeRequired.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { UserPlus, MoreVertical, Pencil, Trash2, Users, Shield, AlertTriangle, Crown, Briefcase, User } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const { canAccess } = usePermissions()
const staffStore = useStaffStore()

// Dialog states
const showAddDialog = ref(false)
const showEditDialog = ref(false)
const showDeleteDialog = ref(false)
const isSubmitting = ref(false)

// Use API roles directly
const availableRoles = computed(() => staffStore.roles)

// Form data
const newStaff = ref<CreateStaffData>({
  email: '',
  password: '',
  first_name: '',
  last_name: '',
  role_id: ''
})

const editingStaff = ref<StaffMember | null>(null)
const staffToDelete = ref<StaffMember | null>(null)

// Edit form data
const editForm = ref({
  email: '',
  first_name: '',
  last_name: '',
  role_id: '',
  password: ''
})

const resetNewStaffForm = () => {
  newStaff.value = {
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    role_id: ''
  }
}

const handleCreateStaff = async () => {
  if (!newStaff.value.email || !newStaff.value.password || !newStaff.value.first_name || !newStaff.value.role_id) {
    toast.error('Please fill in all required fields')
    return
  }
  
  isSubmitting.value = true
  try {
    await staffStore.createStaff(newStaff.value)
    toast.success('Staff member created successfully')
    showAddDialog.value = false
    resetNewStaffForm()
  } catch (e) {
    toast.error((e as Error).message)
  } finally {
    isSubmitting.value = false
  }
}

const openEditDialog = (staff: StaffMember) => {
  editingStaff.value = staff
  editForm.value = {
    email: staff.email,
    first_name: staff.first_name,
    last_name: staff.last_name,
    role_id: staff.role_id,
    password: ''
  }
  showEditDialog.value = true
}

const handleUpdateStaff = async () => {
  if (!editingStaff.value) return
  
  isSubmitting.value = true
  try {
    const updates: Record<string, string> = {}
    if (editForm.value.email !== editingStaff.value.email) updates.email = editForm.value.email
    if (editForm.value.first_name !== editingStaff.value.first_name) updates.first_name = editForm.value.first_name
    if (editForm.value.last_name !== editingStaff.value.last_name) updates.last_name = editForm.value.last_name
    if (editForm.value.role_id !== editingStaff.value.role_id) updates.role_id = editForm.value.role_id
    if (editForm.value.password) updates.password = editForm.value.password
    
    if (Object.keys(updates).length === 0) {
      toast.info('No changes to save')
      showEditDialog.value = false
      return
    }
    
    await staffStore.updateStaff(editingStaff.value.id, updates)
    toast.success('Staff member updated successfully')
    showEditDialog.value = false
  } catch (e) {
    toast.error((e as Error).message)
  } finally {
    isSubmitting.value = false
  }
}

const confirmDelete = (staff: StaffMember) => {
  staffToDelete.value = staff
  showDeleteDialog.value = true
}

const handleDeleteStaff = async () => {
  if (!staffToDelete.value) return
  
  isSubmitting.value = true
  try {
    await staffStore.deleteStaff(staffToDelete.value.id)
    toast.success('Staff member deleted successfully')
    showDeleteDialog.value = false
  } catch (e) {
    toast.error((e as Error).message)
  } finally {
    isSubmitting.value = false
  }
}

const getRoleBadgeColor = (roleName: string) => {
  switch (roleName?.toLowerCase()) {
    case 'admin': return 'bg-red-500/10 text-red-500 border-red-500/20'
    case 'manager': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
    case 'staff': return 'bg-green-500/10 text-green-500 border-green-500/20'
    default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20'
  }
}

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric' 
  })
}

onMounted(() => {
  staffStore.fetchStaff()
  staffStore.fetchRoles()
})
</script>

<template>
  <div v-if="!canAccess(undefined, 'pro')" class="h-full">
    <UpgradeRequired 
      title="Staff Management" 
      description="Manage your team members, assign roles, and control access levels."
      required-plan="Pro"
    />
  </div>
  
  <div v-else class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Staff Management</h1>
        <p class="text-muted-foreground">Manage your team and their access permissions.</p>
      </div>
      <Button @click="showAddDialog = true">
        <UserPlus class="mr-2 h-4 w-4" />
        Add Staff Member
      </Button>
    </div>

    <!-- Stats -->
    <div class="grid gap-4 md:grid-cols-3">
      <Card class="p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-primary/10">
            <Users class="h-5 w-5 text-primary" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ staffStore.staff.length }}</p>
            <p class="text-xs text-muted-foreground">Total Staff</p>
          </div>
        </div>
      </Card>
      <Card class="p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-red-500/10">
            <Shield class="h-5 w-5 text-red-500" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ staffStore.staff.filter(s => s.role_name?.toLowerCase() === 'admin').length }}</p>
            <p class="text-xs text-muted-foreground">Admins</p>
          </div>
        </div>
      </Card>
      <Card class="p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg bg-blue-500/10">
            <Users class="h-5 w-5 text-blue-500" />
          </div>
          <div>
            <p class="text-2xl font-bold">{{ staffStore.roles.length }}</p>
            <p class="text-xs text-muted-foreground">Roles</p>
          </div>
        </div>
      </Card>
    </div>

    <!-- Staff Table -->
    <Card>
      <CardHeader>
        <CardTitle>Team Members</CardTitle>
        <CardDescription>{{ staffStore.staff.length }} active staff member{{ staffStore.staff.length !== 1 ? 's' : '' }}.</CardDescription>
      </CardHeader>
      <CardContent>
        <div v-if="staffStore.isLoading" class="text-center py-8 text-muted-foreground">
          Loading staff...
        </div>
        <div v-else-if="!staffStore.staff.length" class="text-center py-8 text-muted-foreground">
          <Users class="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No staff members yet. Add your first team member!</p>
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b">
                <th class="text-left py-3 px-4 font-medium text-muted-foreground">Name</th>
                <th class="text-left py-3 px-4 font-medium text-muted-foreground">Email</th>
                <th class="text-left py-3 px-4 font-medium text-muted-foreground">Role</th>
                <th class="text-left py-3 px-4 font-medium text-muted-foreground">Joined</th>
                <th class="text-right py-3 px-4 font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="member in staffStore.staff" :key="member.id" class="border-b hover:bg-muted/50 transition-colors">
                <td class="py-3 px-4">
                  <div class="flex items-center gap-3">
                    <div class="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center text-sm font-medium">
                      {{ member.first_name?.charAt(0) }}{{ member.last_name?.charAt(0) }}
                    </div>
                    <div>
                      <p class="font-medium">{{ member.first_name }} {{ member.last_name }}</p>
                    </div>
                  </div>
                </td>
                <td class="py-3 px-4 text-muted-foreground">{{ member.email }}</td>
                <td class="py-3 px-4">
                  <span 
                    class="px-2 py-1 rounded-full text-xs font-medium border"
                    :class="getRoleBadgeColor(member.role_name)"
                  >
                    {{ member.role_name || 'No Role' }}
                  </span>
                </td>
                <td class="py-3 px-4 text-muted-foreground">{{ formatDate(member.created_at) }}</td>
                <td class="py-3 px-4 text-right">
                  <DropdownMenu>
                    <DropdownMenuTrigger as-child>
                      <Button variant="ghost" size="icon" class="h-8 w-8">
                        <MoreVertical class="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem @click="openEditDialog(member)">
                        <Pencil class="mr-2 h-4 w-4" />
                        Edit
                      </DropdownMenuItem>
                      <DropdownMenuItem class="text-destructive" @click="confirmDelete(member)">
                        <Trash2 class="mr-2 h-4 w-4" />
                        Delete
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>

    <!-- Add Staff Dialog -->
    <Dialog v-model:open="showAddDialog">
      <DialogContent class="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Add Staff Member</DialogTitle>
          <DialogDescription>Create a new account for a team member.</DialogDescription>
        </DialogHeader>
        <form @submit.prevent="handleCreateStaff" class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>First Name *</Label>
              <Input v-model="newStaff.first_name" placeholder="John" autocomplete="given-name" />
            </div>
            <div class="space-y-2">
              <Label>Last Name</Label>
              <Input v-model="newStaff.last_name" placeholder="Doe" autocomplete="family-name" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Email *</Label>
            <Input v-model="newStaff.email" type="email" placeholder="john@example.com" autocomplete="email" />
          </div>
          <div class="space-y-2">
            <Label>Password *</Label>
            <Input v-model="newStaff.password" type="password" placeholder="Min. 6 characters" autocomplete="new-password" />
          </div>
          <div class="space-y-2">
            <Label>Role *</Label>
            <RadioGroup v-model="newStaff.role_id" class="grid grid-cols-3 gap-2">
              <div
                v-for="role in availableRoles"
                :key="role.id"
                class="relative flex flex-col items-center gap-2 rounded-lg border border-input p-3 cursor-pointer transition-colors hover:bg-accent has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary/5"
              >
                <RadioGroupItem
                  :id="`role-${role.id}`"
                  :value="role.id"
                  class="sr-only"
                />
                <component
                  :is="role.name === 'Admin' ? Crown : role.name === 'Manager' ? Briefcase : User"
                  class="h-5 w-5 opacity-60"
                  aria-hidden="true"
                />
                <Label :for="`role-${role.id}`" class="text-xs font-medium cursor-pointer">{{ role.name }}</Label>
              </div>
            </RadioGroup>
          </div>
          <DialogFooter class="pt-2">
            <Button type="button" variant="outline" @click="showAddDialog = false">Cancel</Button>
            <Button type="submit" :disabled="isSubmitting">
              {{ isSubmitting ? 'Creating...' : 'Create Staff' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>

    <!-- Edit Staff Dialog -->
    <Dialog v-model:open="showEditDialog">
      <DialogContent class="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit Staff Member</DialogTitle>
          <DialogDescription>Update staff member information.</DialogDescription>
        </DialogHeader>
        <form @submit.prevent="handleUpdateStaff" class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>First Name</Label>
              <Input v-model="editForm.first_name" autocomplete="given-name" />
            </div>
            <div class="space-y-2">
              <Label>Last Name</Label>
              <Input v-model="editForm.last_name" autocomplete="family-name" />
            </div>
          </div>
          <div class="space-y-2">
            <Label>Email</Label>
            <Input v-model="editForm.email" type="email" autocomplete="email" />
          </div>
          <div class="space-y-2">
            <Label>New Password (leave blank to keep)</Label>
            <Input v-model="editForm.password" type="password" placeholder="Enter new password" autocomplete="new-password" />
          </div>
          <div class="space-y-2">
            <Label>Role</Label>
            <RadioGroup v-model="editForm.role_id" class="grid grid-cols-3 gap-2">
              <div
                v-for="role in availableRoles"
                :key="role.id"
                class="relative flex flex-col items-center gap-2 rounded-lg border border-input p-3 cursor-pointer transition-colors hover:bg-accent has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary/5"
              >
                <RadioGroupItem
                  :id="`edit-role-${role.id}`"
                  :value="role.id"
                  class="sr-only"
                />
                <component
                  :is="role.name === 'Admin' ? Crown : role.name === 'Manager' ? Briefcase : User"
                  class="h-5 w-5 opacity-60"
                  aria-hidden="true"
                />
                <Label :for="`edit-role-${role.id}`" class="text-xs font-medium cursor-pointer">{{ role.name }}</Label>
              </div>
            </RadioGroup>
          </div>
          <DialogFooter class="pt-2">
            <Button type="button" variant="outline" @click="showEditDialog = false">Cancel</Button>
            <Button type="submit" :disabled="isSubmitting">
              {{ isSubmitting ? 'Saving...' : 'Save Changes' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog v-model:open="showDeleteDialog">
      <DialogContent class="sm:max-w-[400px]">
        <DialogHeader>
          <div class="flex items-center gap-3">
            <div class="p-2 rounded-full bg-destructive/10">
              <AlertTriangle class="h-5 w-5 text-destructive" />
            </div>
            <DialogTitle>Delete Staff Member</DialogTitle>
          </div>
          <DialogDescription>
            Are you sure you want to delete <strong>{{ staffToDelete?.first_name }} {{ staffToDelete?.last_name }}</strong>? 
            This action cannot be undone.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter class="mt-4">
          <Button variant="outline" @click="showDeleteDialog = false">Cancel</Button>
          <Button variant="destructive" @click="handleDeleteStaff" :disabled="isSubmitting">
            {{ isSubmitting ? 'Deleting...' : 'Delete' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
