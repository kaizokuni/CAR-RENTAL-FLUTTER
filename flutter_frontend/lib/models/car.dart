class Car {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String status;
  final double pricePerDay;
  final String currency;
  final String? imageUrl;
  final List<String> images;
  final String? transmission;
  final String? fuelType;
  final int seats;
  final String? description;
  final String? category;
  final DateTime? createdAt;
  final String? tenantId;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.status = 'available',
    required this.pricePerDay,
    this.currency = 'MAD',
    this.imageUrl,
    this.images = const [],
    this.transmission,
    this.fuelType,
    this.seats = 5,
    this.description,
    this.category,
    this.createdAt,
    this.tenantId,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      licensePlate: json['license_plate'] ?? '',
      status: json['status'] ?? 'available',
      pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'MAD',
      imageUrl: json['image_url'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      transmission: json['transmission'],
      fuelType: json['fuel_type'],
      seats: json['seats'] ?? 5,
      description: json['description'],
      category: json['category'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      tenantId: json['tenant_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'status': status,
      'price_per_day': pricePerDay,
      'currency': currency,
      'image_url': imageUrl,
      'images': images,
      'transmission': transmission,
      'fuel_type': fuelType,
      'seats': seats,
      'description': description,
      'tenant_id': tenantId,
    };
  }

  String get displayName => '$brand $model';
  
  // Returns primary image URL - prefers imageUrl, falls back to first image in images array
  String? get primaryImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl;
    }
    if (images.isNotEmpty) {
      return images.first;
    }
    return null;
  }
  
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'rented':
        return 'Rented';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }
}
