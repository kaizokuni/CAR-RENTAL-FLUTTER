import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customers_provider.dart';
import '../../models/customer.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customersProvider.notifier).fetchCustomers();
    });
  }

  List<Customer> get filteredCustomers {
    final customers = ref.watch(customersProvider).customers;
    if (_searchQuery.isEmpty) return customers;
    return customers.where((c) =>
      c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (c.phone?.contains(_searchQuery) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

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
                      'Customers',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customersState.customers.length} registered customers',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomerDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers by name, email or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 24),

          // Customers Grid
          Expanded(
            child: customersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customersState.error != null
                    ? Center(child: Text('Error: ${customersState.error}'))
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No customers found',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return _buildCustomerCard(context, customer);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    customer.firstName.isNotEmpty 
                        ? customer.firstName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.licenseNumber != null)
                        Text(
                          'License: ${customer.licenseNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.email,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (customer.phone != null && customer.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    customer.phone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name *'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                // License Number field removed - column doesn't exist in DB
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
              final data = {
                'first_name': firstNameController.text,
                'last_name': lastNameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                // license_number field removed - doesn't exist in DB schema
              };

              try {
                await ref.read(customersProvider.notifier).createCustomer(data);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
