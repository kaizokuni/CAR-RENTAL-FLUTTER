import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState.isSuperAdmin;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return Scaffold(
      drawer: isDesktop ? null : _buildSidebar(context, ref, authState, isSuperAdmin, true),
      appBar: isDesktop 
          ? null 
          : AppBar(
              title: Text(authState.tenant?.name ?? 'Car Rental'),
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, ref, authState, isSuperAdmin, false),
          
          // Main Content
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, AuthState authState, bool isSuperAdmin, bool isDrawer) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: isDrawer ? BorderSide.none : BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo & Brand
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.tenant?.name ?? 'Car Rental',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.tenant?.subscriptionTier.toUpperCase() ?? 'FREE',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (isSuperAdmin) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin Hub',
                    path: '/admin',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Divider(height: 1),
                  ),
                ],
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Overview',
                  path: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.directions_car_rounded,
                  label: 'Fleet Management',
                  path: '/fleet',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_month_rounded,
                  label: 'Reservations',
                  path: '/bookings',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.request_page_rounded,
                  label: 'Booking Requests',
                  path: '/booking-requests',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.group_rounded,
                  label: 'Customers',
                  path: '/customers',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.badge_rounded,
                  label: 'Staff Members',
                  path: '/staff',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.analytics_rounded,
                  label: 'Financials',
                  path: '/financials',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.auto_graph_rounded,
                  label: 'Marketing Hub',
                  path: '/marketing',
                ),
              ],
            ),
          ),
          
          // User Section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      authState.user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authState.user?.fullName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.role?.replaceAll('_', ' ').toUpperCase() ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  tooltip: 'Logout',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
  }) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = currentPath == path;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.12),
                    colorScheme.primary.withOpacity(0.04),
                  ],
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (currentPath == path) return;
              context.go(path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected 
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: isSelected 
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
