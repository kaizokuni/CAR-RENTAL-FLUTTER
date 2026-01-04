class BookingRequest {
  final String id;
  final String? tenantId;
  final String? carId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String? pickupLocation;
  final bool deliveryRequested;
  final String? message;
  final String status; // pending, contacted, confirmed, rejected
  final DateTime createdAt;
  
  // Car details (when joined from backend)
  final String? carBrand;
  final String? carModel;
  final String? carImageUrl;

  const BookingRequest({
    required this.id,
    this.tenantId,
    this.carId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.pickupDate,
    required this.returnDate,
    this.pickupLocation,
    this.deliveryRequested = false,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.carBrand,
    this.carModel,
    this.carImageUrl,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String?,
      carId: json['car_id'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      customerEmail: json['customer_email'] as String?,
      pickupDate: DateTime.parse(json['pickup_date'] as String),
      returnDate: DateTime.parse(json['return_date'] as String),
      pickupLocation: json['pickup_location'] as String?,
      deliveryRequested: json['delivery_requested'] as bool? ?? false,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      carBrand: json['car_brand'] as String?,
      carModel: json['car_model'] as String?,
      carImageUrl: json['car_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'car_id': carId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'pickup_date': pickupDate.toIso8601String(),
      'return_date': returnDate.toIso8601String(),
      'pickup_location': pickupLocation,
      'delivery_requested': deliveryRequested,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BookingRequest copyWith({
    String? id,
    String? tenantId,
    String? carId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? pickupDate,
    DateTime? returnDate,
    String? pickupLocation,
    bool? deliveryRequested,
    String? message,
    String? status,
    DateTime? createdAt,
    String? carBrand,
    String? carModel,
    String? carImageUrl,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      carId: carId ?? this.carId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      pickupDate: pickupDate ?? this.pickupDate,
      returnDate: returnDate ?? this.returnDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryRequested: deliveryRequested ?? this.deliveryRequested,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      carImageUrl: carImageUrl ?? this.carImageUrl,
    );
  }

  int get durationDays {
    return returnDate.difference(pickupDate).inDays + 1;
  }

  bool get isPending => status == 'pending';
  bool get isContacted => status == 'contacted';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
}
