class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? roleId;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      roleId: json['role_id'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class Tenant {
  final String id;
  final String name;
  final String subdomain;
  final String? dbName;
  final String subscriptionTier;
  final DateTime? createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.subdomain,
    this.dbName,
    this.subscriptionTier = 'normal',
    this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subdomain: json['subdomain'] ?? '',
      dbName: json['db_name'],
      subscriptionTier: json['subscription_tier'] ?? 'normal',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
}

class AuthState {
  final User? user;
  final Tenant? tenant;
  final String? token;
  final String? role;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.tenant,
    this.token,
    this.role,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isSuperAdmin => role == 'super_admin';
  
  AuthState copyWith({
    User? user,
    Tenant? tenant,
    String? token,
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      tenant: tenant ?? this.tenant,
      token: token ?? this.token,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
