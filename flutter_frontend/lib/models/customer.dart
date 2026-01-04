class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? licenseNumber;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.licenseNumber,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      licenseNumber: json['license_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'license_number': licenseNumber,
    };
  }

  String get fullName => '$firstName $lastName';
}
