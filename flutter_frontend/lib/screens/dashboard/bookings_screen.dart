import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/cars_provider.dart';
import '../../models/booking.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).fetchBookings();
      ref.read(carsProvider.notifier).fetchCars();
    });
  }

  List<Booking> get filteredBookings {
    final bookings = ref.watch(bookingsProvider).bookings;
    return bookings.where((booking) {
      final matchesSearch = booking.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'all' || 
          booking.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(bookingsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bookingsState.bookings.length} total bookings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateBookingDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Booking'),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by customer name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bookings Table
          Expanded(
            child: bookingsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingsState.error != null
                    ? Center(child: Text('Error: ${bookingsState.error}'))
                    : filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings found',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Card(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Customer')),
                                  DataColumn(label: Text('Car')),
                                  DataColumn(label: Text('Start Date')),
                                  DataColumn(label: Text('End Date')),
                                  DataColumn(label: Text('Total')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filteredBookings.map((booking) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(booking.customerName)),
                                      DataCell(Text(booking.carDisplay)),
                                      DataCell(Text(DateFormat('MMM d, y').format(booking.startDate))),
                                      DataCell(Text(DateFormat('MMM d, y').format(booking.endDate))),
                                      DataCell(Text('${booking.totalPrice.toStringAsFixed(0)} MAD')),
                                      DataCell(_buildStatusBadge(context, booking.status)),
                                      DataCell(
                                        PopupMenuButton<String>(
                                          onSelected: (value) => _handleStatusUpdate(booking, value),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
                                            const PopupMenuItem(value: 'active', child: Text('Start')),
                                            const PopupMenuItem(value: 'completed', child: Text('Complete')),
                                            const PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
                                          ],
                                          child: const Icon(Icons.more_vert),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.grey;
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
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleStatusUpdate(Booking booking, String newStatus) async {
    try {
      await ref.read(bookingsProvider.notifier).updateBookingStatus(booking.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateBookingDialog(BuildContext context) {
    final customerController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedCarId;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cars = ref.watch(carsProvider).cars;
          
          return AlertDialog(
            title: const Text('New Booking'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: customerController,
                      decoration: const InputDecoration(labelText: 'Customer Name *'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCarId,
                      decoration: const InputDecoration(labelText: 'Select Car *'),
                      hint: const Text('Choose a car'),
                      items: cars.map((car) {
                        return DropdownMenuItem<String>(
                          value: car.id,
                          child: Text('${car.brand} ${car.model} (${car.year})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCarId = value);
                        // Auto-calculate price based on car's daily rate
                        if (value != null) {
                          final car = cars.firstWhere((c) => c.id == value);
                          final days = endDate.difference(startDate).inDays + 1;
                          priceController.text = (car.pricePerDay * days).toStringAsFixed(0);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            startDate = date;
                            // Recalculate price
                            if (selectedCarId != null) {
                              final car = cars.firstWhere((c) => c.id == selectedCarId);
                              final days = endDate.difference(startDate).inDays + 1;
                              priceController.text = (car.pricePerDay * days).toStringAsFixed(0);
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            endDate = date;
                            // Recalculate price
                            if (selectedCarId != null) {
                              final car = cars.firstWhere((c) => c.id == selectedCarId);
                              final days = endDate.difference(startDate).inDays + 1;
                              priceController.text = (car.pricePerDay * days).toStringAsFixed(0);
                            }
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Total Price *',
                        suffixText: 'MAD',
                      ),
                      keyboardType: TextInputType.number,
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
                onPressed: selectedCarId == null ? null : () async {
                  final data = {
                    'customer_name': customerController.text,
                    'car_id': selectedCarId,
                    // Use RFC3339 format that Go expects: YYYY-MM-DDTHH:MM:SSZ
                    'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T00:00:00Z',
                    'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}T00:00:00Z',
                    'total_price': double.tryParse(priceController.text) ?? 0,
                  };

                  try {
                    await ref.read(bookingsProvider.notifier).createBooking(data);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

