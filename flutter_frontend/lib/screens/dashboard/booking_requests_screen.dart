import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_request.dart';
import '../../providers/booking_requests_provider.dart';

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bookingRequestsProvider.notifier).fetchBookingRequests());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingRequestsProvider);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Requests',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage incoming booking requests from your landing page',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(bookingRequestsProvider.notifier).fetchBookingRequests(),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Contacted', 'contacted'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Confirmed', 'confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Rejected', 'rejected'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer name, phone, or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: state.isLoading && state.requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _buildErrorState(context, state.error!)
                      : _buildRequestsList(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? status) {
    final state = ref.watch(bookingRequestsProvider);
    final isSelected = state.selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(bookingRequestsProvider.notifier).setStatusFilter(status);
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(bookingRequestsProvider.notifier).fetchBookingRequests(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, BookingRequestsState state) {
    var requests = state.filteredRequests;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      requests = requests.where((req) {
        final query = _searchQuery.toLowerCase();
        return req.customerName.toLowerCase().contains(query) ||
            req.customerPhone.toLowerCase().contains(query) ||
            (req.customerEmail?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (requests.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildRequestCard(context, requests[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No booking requests found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Requests from your landing page will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, BookingRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        request.customerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, request.status),
              ],
            ),
            const Divider(height: 24),

            // Contact Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.phone, request.customerPhone),
                      if (request.customerEmail != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.email, request.customerEmail!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Booking Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PICKUP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(request.pickupDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RETURN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(request.returnDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${request.durationDays} ${request.durationDays == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            // Car Info (if available)
            if (request.carBrand != null || request.carModel != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${request.carBrand ?? ''} ${request.carModel ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            // Additional Info
            if (request.pickupLocation != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, request.pickupLocation!),
            ],
            
            if (request.deliveryRequested) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery Requested',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Customer Message:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.message!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (request.status == 'pending' || request.status == 'contacted') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (request.status == 'pending')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsContacted(request.id),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Contacted'),
                      ),
                    ),
                  if (request.status == 'pending') const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createBooking(context, request),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Create Booking'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _rejectRequest(request.id),
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'contacted':
        color = Colors.blue;
        icon = Icons.phone_in_talk;
        break;
      case 'confirmed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Future<void> _markAsContacted(String requestId) async {
    try {
      await ref.read(bookingRequestsProvider.notifier).updateRequestStatus(requestId, 'contacted');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as contacted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request?'),
        content: const Text('Are you sure you want to reject this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingRequestsProvider.notifier).updateRequestStatus(requestId, 'rejected');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _createBooking(BuildContext context, BookingRequest request) {
    // Navigate to bookings screen with pre-filled data
    // We'll pass the request details as extra data
    context.go('/bookings', extra: {
      'customerName': request.customerName,
      'customerPhone': request.customerPhone,
      'customerEmail': request.customerEmail,
      'carId': request.carId,
      'startDate': request.pickupDate,
      'endDate': request.returnDate,
      'requestId': request.id,
    });
  }
}
