import { createRouter, createWebHistory } from 'vue-router'
import Login from '../pages/Login.vue'
import Signup from '../pages/Signup.vue'
import { jwtDecode } from 'jwt-decode'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/login'
    },
    {
      path: '/login',
      name: 'login',
      component: Login
    },
    {
      path: '/signup',
      name: 'signup',
      component: Signup
    },
    {
      path: '/dashboard',
      component: () => import('../layouts/DashboardLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('../pages/Dashboard.vue')
        },
        {
          path: 'cars',
          name: 'cars',
          component: () => import('../pages/dashboard/Fleet.vue')
        },
        {
          path: 'bookings',
          name: 'bookings',
          component: () => import('../pages/dashboard/Bookings.vue')
        },
        {
          path: 'customers',
          name: 'customers',
          component: () => import('../pages/dashboard/Customers.vue')
        },
        {
          path: 'financials',
          name: 'financials',
          component: () => import('../pages/dashboard/Financials.vue')
        },
        {
          path: 'staff',
          name: 'staff',
          component: () => import('../pages/dashboard/Staff.vue')
        },
        {
          path: 'branding',
          name: 'branding',
          component: () => import('../pages/dashboard/Branding.vue')
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('../pages/dashboard/Profile.vue')
        },
        {
          path: 'reports',
          name: 'reports',
          component: () => import('../pages/dashboard/Reports.vue')
        },
        {
          path: 'admin/dashboard',
          name: 'admin-dashboard',
          component: () => import('../pages/admin/Dashboard.vue'),
          meta: { requiresAuth: true }
        },
        {
          path: 'admin/tenants/new',
          name: 'create-tenant',
          component: () => import('../pages/admin/CreateTenant.vue'),
          meta: { requiresAuth: true }
        },
        {
          path: 'admin/tenants/:id',
          name: 'tenant-details',
          component: () => import('../pages/admin/TenantDetails.vue'),
          meta: { requiresAuth: true }
        }
      ]
    },
    {
      path: '/403',
      name: 'unauthorized',
      component: () => import('../pages/Unauthorized.vue')
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('../pages/NotFound.vue')
    }
  ]
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  
  // Decode token to check role
  let userRole = null
  if (token) {
    try {
      const decoded: any = jwtDecode(token)
      userRole = decoded.role
    } catch (e) {
      // Invalid token
    }
  }
  
  // Protect routes that require authentication
  if (to.meta.requiresAuth && !token) {
    next('/login')
    return
  }
  
  // Protect admin routes - require super_admin role
  if (to.path.startsWith('/dashboard/admin')) {
    if (userRole !== 'super_admin') {
      next('/403')
      return
    }
  }
  
  // If already logged in and trying to access login/signup, redirect to dashboard
  if (token && (to.name === 'login' || to.name === 'signup')) {
    if (userRole === 'super_admin') {
      next('/dashboard/admin/dashboard')
    } else {
      next('/dashboard')
    }
    return
  }
  
  next()
})

export default router
