import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../models/car.dart';
import '../../providers/cars_provider.dart';
import '../../widgets/multi_image_picker.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(carsProvider.notifier).fetchCars();
    });
  }

  List<Car> get filteredCars {
    final cars = ref.watch(carsProvider).cars;
    return cars.where((car) {
      final matchesSearch = car.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.licensePlate.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'all' || 
          car.status.toLowerCase() == _statusFilter.toLowerCase();
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final carsState = ref.watch(carsProvider);

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
                      'Fleet Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${carsState.cars.length} vehicles in your fleet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCarDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Car'),
                ),
              ],
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search cars...',
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
                
                // Status Filter
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
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'rented', child: Text('Rented')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Cars Grid
          Expanded(
            child: carsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : carsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(carsState.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(carsProvider.notifier).fetchCars(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredCars.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No cars in your fleet' : 'No cars match your search',
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
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredCars.length,
                            itemBuilder: (context, index) {
                              final car = filteredCars[index];
                              return _buildCarCard(context, car);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Car car) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optional: View car details
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCarImage(context, car),
                    
                    // Glassmorphism-style Status Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildStatusBadge(context, car.status),
                    ),
                  ],
                ),
              ),
              
              // Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            car.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${car.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.licensePlate.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY RATE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${car.pricePerDay.toStringAsFixed(0)} ${car.currency}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 20),
                                onPressed: () => _showEditCarDialog(context, car),
                                tooltip: 'Quick Edit',
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () => _confirmDelete(context, car),
                                tooltip: 'Remove Vehicle',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ],
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
    IconData icon;
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'rented':
        color = Colors.blue;
        icon = Icons.key_rounded;
        break;
      case 'maintenance':
        color = Colors.orange;
        icon = Icons.build_circle_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarImage(BuildContext context, Car car) {
    // Use primaryImageUrl which falls back to images array
    final imageUrl = car.primaryImageUrl;
    
    // No image URL provided
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.directions_car_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      );
    }

    // Check for base64 data URL
    if (imageUrl.startsWith('data:image/')) {
      try {
        // Extract base64 data
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        );
      }
    }

    // Regular HTTP(S) URL
    return CachedNetworkImage(
      imageUrl: imageUrl.startsWith('http')
          ? imageUrl
          : 'http://localhost:8080$imageUrl',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
    );
  }

  void _showAddCarDialog(BuildContext context) {
    _showCarFormDialog(context, null);
  }

  void _showEditCarDialog(BuildContext context, Car car) {
    _showCarFormDialog(context, car);
  }

  void _showCarFormDialog(BuildContext context, Car? car) {
    final isEditing = car != null;
    final brandController = TextEditingController(text: car?.brand ?? '');
    final modelController = TextEditingController(text: car?.model ?? '');
    final yearController = TextEditingController(text: car?.year.toString() ?? '');
    final plateController = TextEditingController(text: car?.licensePlate ?? '');
    final priceController = TextEditingController(text: car?.pricePerDay.toStringAsFixed(0) ?? '');
    String status = car?.status.toLowerCase() ?? 'available';
    List<String> images = List.from(car?.images ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Car' : 'Add New Car'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(labelText: 'Brand *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(labelText: 'Model *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Year *'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(labelText: 'License Plate *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Day *',
                      suffixText: 'MAD',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  MultiImagePicker(
                    initialImages: images,
                    onImagesChanged: (newImages) {
                      setDialogState(() => images = newImages);
                    },
                    maxImages: 8,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'rented', child: Text('Rented')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => status = value ?? 'available');
                    },
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
                final data = {
                  'brand': brandController.text,
                  'model': modelController.text,
                  'year': int.tryParse(yearController.text) ?? 2024,
                  'license_plate': plateController.text,
                  'price_per_day': double.tryParse(priceController.text) ?? 0,
                  'status': status,
                  'images': images,
                };

                try {
                  if (isEditing) {
                    await ref.read(carsProvider.notifier).updateCar(car!.id, data);
                  } else {
                    await ref.read(carsProvider.notifier).createCar(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Car car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await ref.read(carsProvider.notifier).deleteCar(car.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
