import { 
  LayoutDashboard, 
  Building2, 
  BarChart3, 
  Server, 
  CreditCard,
  Car,
  Calendar,
  Users,
  UserCog,
  DollarSign,
  Palette,
  Globe,
  Settings,
  FileText
} from 'lucide-vue-next'

export interface SidebarItem {
  icon: any
  label: string
  path: string
  requiresRole?: string
  requiresSubscription?: 'pro' | 'premium'
  badge?: string
  readonly?: boolean
  children?: SidebarItem[]
}

export interface SidebarConfig {
  sections: SidebarItem[]
}

// Super Admin Sidebar - Platform Management
export const superAdminSidebar: SidebarConfig = {
  sections: [
    {
      icon: LayoutDashboard,
      label: 'Overview',
      path: '/dashboard/admin/dashboard'
    },
    {
      icon: Building2,
      label: 'Shops',
      path: '/dashboard/admin/dashboard' // Main dashboard shows shops
    },
    {
      icon: BarChart3,
      label: 'Analytics',
      path: '/dashboard/admin/analytics' // Future
    },
    {
      icon: Server,
      label: 'System Health',
      path: '/dashboard/admin/health' // Future
    },
    {
      icon: CreditCard,
      label: 'Billing',
      path: '/dashboard/admin/billing' // Future
    }
  ]
}

// Owner/Admin Sidebar - Shop Management
export const ownerSidebar: SidebarConfig = {
  sections: [
    {
      icon: LayoutDashboard,
      label: 'Dashboard',
      path: '/dashboard'
    },
    {
      icon: Car,
      label: 'Fleet',
      path: '/dashboard/cars'
    },
    {
      icon: Calendar,
      label: 'Bookings',
      path: '/dashboard/bookings'
    },
    {
      icon: Users,
      label: 'Customers',
      path: '/dashboard/customers'
    },
    {
      icon: UserCog,
      label: 'Staff',
      path: '/dashboard/staff',
      requiresSubscription: 'pro',
      badge: 'PRO'
    },
    {
      icon: DollarSign,
      label: 'Financials',
      path: '/dashboard/financials',
      requiresSubscription: 'pro',
      badge: 'PRO'
    },
    {
      icon: Palette,
      label: 'Marketing',
      path: '/dashboard/marketing',
      requiresSubscription: 'premium',
      badge: 'PREMIUM'
    },
    {
      icon: FileText,
      label: 'Reports',
      path: '/dashboard/reports'
    },
    {
      icon: Settings,
      label: 'Settings',
      path: '/dashboard/profile'
    }
  ]
}

// Manager Sidebar - Similar to Owner but no staff/financial management
export const managerSidebar: SidebarConfig = {
  sections: [
    {
      icon: LayoutDashboard,
      label: 'Dashboard',
      path: '/dashboard'
    },
    {
      icon: Car,
      label: 'Fleet',
      path: '/dashboard/cars'
    },
    {
      icon: Calendar,
      label: 'Bookings',
      path: '/dashboard/bookings'
    },
    {
      icon: Users,
      label: 'Customers',
      path: '/dashboard/customers'
    },
    {
      icon: FileText,
      label: 'Reports',
      path: '/dashboard/reports',
      readonly: true
    }
  ]
}

// Assistant Sidebar - Limited Access
export const assistantSidebar: SidebarConfig = {
  sections: [
    {
      icon: LayoutDashboard,
      label: 'Dashboard',
      path: '/dashboard',
      readonly: true
    },
    {
      icon: Car,
      label: 'View Cars',
      path: '/dashboard/cars',
      readonly: true
    },
    {
      icon: Calendar,
      label: 'Bookings',
      path: '/dashboard/bookings'
    },
    {
      icon: Users,
      label: 'Customers',
      path: '/dashboard/customers',
      readonly: true
    }
  ]
}

// Get sidebar config based on role
export function getSidebarConfig(role: string): SidebarConfig {
  switch (role) {
    case 'super_admin':
      return superAdminSidebar
    case 'admin':
    case 'owner':
      return ownerSidebar
    case 'manager':
      return managerSidebar
    case 'assistant':
      return assistantSidebar
    default:
      return ownerSidebar // Default to owner sidebar
  }
}
