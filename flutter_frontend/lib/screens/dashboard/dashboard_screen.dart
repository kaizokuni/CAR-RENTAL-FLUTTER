import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cars_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/customers_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data on load
    Future.microtask(() {
      ref.read(carsProvider.notifier).fetchCars();
      ref.read(bookingsProvider.notifier).fetchBookings();
      ref.read(customersProvider.notifier).fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final carsState = ref.watch(carsProvider);
    final bookingsState = ref.watch(bookingsProvider);
    final customersCount = ref.watch(customersCountProvider);
    final availableCars = ref.watch(availableCarsCountProvider);
    final rentedCars = ref.watch(rentedCarsCountProvider);
    final maintenanceCars = ref.watch(maintenanceCarsCountProvider);

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
                      'Welcome back, ${authState.user?.firstName ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening with your business',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Total Cars',
                      value: carsState.cars.length.toString(),
                      icon: Icons.directions_car,
                      color: Colors.blue,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Available',
                      value: availableCars.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Rented',
                      value: rentedCars.toString(),
                      icon: Icons.schedule,
                      color: Colors.orange,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Customers',
                      value: customersCount.toString(),
                      icon: Icons.people,
                      color: Colors.purple,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Recent Activity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Bookings
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Bookings',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (bookingsState.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (bookingsState.bookings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No bookings yet',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...bookingsState.bookings.take(5).map((booking) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(booking.customerName),
                              subtitle: Text(booking.carDisplay),
                              trailing: _buildStatusBadge(context, booking.status),
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Fleet Status
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fleet Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildFleetStatusItem(
                            context,
                            label: 'Available',
                            count: availableCars,
                            total: carsState.cars.length,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildFleetStatusItem(
                            context,
                            label: 'Rented',
                            count: rentedCars,
                            total: carsState.cars.length,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildFleetStatusItem(
                            context,
                            label: 'Maintenance',
                            count: maintenanceCars,
                            total: carsState.cars.length,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
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
              Expanded(
                child: Column(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFleetStatusItem(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
