import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchStats();
      ref.read(adminProvider.notifier).fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Super Admin Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your car rental platform',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTenantDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Shop'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Shops',
                    value: adminState.stats?.totalTenants.toString() ?? '0',
                    icon: Icons.store,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Active Shops',
                    value: adminState.stats?.activeTenants.toString() ?? '0',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'New This Month',
                    value: adminState.stats?.newThisMonth.toString() ?? '0',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tenants List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Shops',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your car rental shop tenants',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Divider(height: 32),

                    if (adminState.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (adminState.error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('Error: ${adminState.error}'),
                        ),
                      )
                    else if (adminState.tenants.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              const Text('No shops created yet'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...adminState.tenants.map((tenant) => _buildTenantRow(context, tenant)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantRow(BuildContext context, Tenant tenant) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    _buildTierBadge(context, tenant.subscriptionTier),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${tenant.subdomain}.localhost:5173',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 8),
                    Text(
                      tenant.createdAt != null
                          ? 'Created ${DateFormat('MMM d, y').format(tenant.createdAt!)}'
                          : '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showSubscriptionDialog(context, tenant),
            icon: const Icon(Icons.credit_card, size: 16),
            label: const Text('Manage Plan'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _handleImpersonate(context, tenant),
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Login as Owner'),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(BuildContext context, String tier) {
    Color color;
    switch (tier.toLowerCase()) {
      case 'premium':
        color = Colors.purple;
        break;
      case 'pro':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, Tenant tenant) {
    String selectedTier = tenant.subscriptionTier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Subscription'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update the subscription plan for ${tenant.name}'),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: selectedTier,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Tier',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text('Normal - Basic features'),
                    ),
                    DropdownMenuItem(
                      value: 'pro',
                      child: Text('Pro - Advanced reports'),
                    ),
                    DropdownMenuItem(
                      value: 'premium',
                      child: Text('Premium - All features'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedTier = value ?? 'normal');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(adminProvider.notifier).updateSubscription(
                    tenant.id,
                    selectedTier,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${tenant.name} to $selectedTier')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleImpersonate(BuildContext context, Tenant tenant) async {
    try {
      final token = await ref.read(adminProvider.notifier).impersonateTenant(tenant.id);
      
      // Save the new token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      // Reload the app
      if (context.mounted) {
        context.go('/dashboard');
        // Force refresh auth state
        ref.read(authProvider.notifier).fetchUser();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateTenantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final subdomainController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Shop'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Shop Name *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subdomainController,
                  decoration: const InputDecoration(
                    labelText: 'Subdomain *',
                    helperText: 'e.g. "myshop" will be accessible at myshop.carrent.com',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Owner Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Owner Password *'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement create tenant API call
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shop creation not implemented in MVP')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
