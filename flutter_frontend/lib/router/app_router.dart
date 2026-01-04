import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/fleet_screen.dart';
import '../screens/dashboard/bookings_screen.dart';
import '../screens/dashboard/booking_requests_screen.dart';
import '../screens/dashboard/customers_screen.dart';
import '../screens/dashboard/staff_screen.dart';
import '../screens/dashboard/financials_screen.dart';
import '../screens/dashboard/marketing_screen.dart';
import '../screens/landing_page_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../widgets/dashboard_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isLoading = authState.isLoading;

      // Still loading auth state
      if (isLoading) return null;

      // Not authenticated, redirect to login unless on public landing page
      if (!isAuthenticated && !isLoggingIn && state.matchedLocation != '/') {
        return '/login';
      }

      // Authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        if (authState.isSuperAdmin) {
          return '/admin';
        }
        return '/dashboard';
      }

      // Admin route protection
      if (state.matchedLocation.startsWith('/admin') && !authState.isSuperAdmin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicLandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/fleet',
            builder: (context, state) => const FleetScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/booking-requests',
            builder: (context, state) => const BookingRequestsScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: '/financials',
            builder: (context, state) => const FinancialsScreen(),
          ),
          GoRoute(
            path: '/marketing',
            builder: (context, state) => const MarketingScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ],
      ),
    ],
  );
});
