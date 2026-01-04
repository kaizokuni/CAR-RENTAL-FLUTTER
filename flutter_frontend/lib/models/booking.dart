class Booking {
  final String id;
  final String carId;
  final String? customerId;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalPrice;
  final String? carMake;
  final String? carModel;

  Booking({
    required this.id,
    required this.carId,
    this.customerId,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    this.status = 'pending',
    required this.totalPrice,
    this.carMake,
    this.carModel,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      carId: json['car_id'] ?? '',
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'pending',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      carMake: json['car_make'],
      carModel: json['car_model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'customer_id': customerId,
      'customer_name': customerName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_price': totalPrice,
    };
  }

  String get carDisplay => carMake != null && carModel != null 
      ? '$carMake $carModel' 
      : 'Car #$carId';

  int get durationDays => endDate.difference(startDate).inDays;
}
