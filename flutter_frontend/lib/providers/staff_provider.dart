import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class StaffMember {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? roleId;
  final String? roleName;
  final String? createdAt;

  StaffMember({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roleId,
    this.roleName,
    this.createdAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      roleId: json['role_id'],
      roleName: json['role_name'],
      createdAt: json['created_at'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class Role {
  final String id;
  final String name;
  final String? description;

  Role({required this.id, required this.name, this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class StaffState {
  final List<StaffMember> staff;
  final List<Role> roles;
  final bool isLoading;
  final String? error;

  StaffState({
    this.staff = const [],
    this.roles = const [],
    this.isLoading = false,
    this.error,
  });

  StaffState copyWith({
    List<StaffMember>? staff,
    List<Role>? roles,
    bool? isLoading,
    String? error,
  }) {
    return StaffState(
      staff: staff ?? this.staff,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final staffProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  final api = ref.read(apiServiceProvider);
  return StaffNotifier(api);
});

class StaffNotifier extends StateNotifier<StaffState> {
  final ApiService _api;

  StaffNotifier(this._api) : super(StaffState());

  Future<void> fetchStaff() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList(ApiConfig.staff);
      final staff = response.map((json) => StaffMember.fromJson(json)).toList();
      state = state.copyWith(staff: staff, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRoles() async {
    try {
      final response = await _api.getList(ApiConfig.roles);
      final roles = response.map((json) => Role.fromJson(json)).toList();
      state = state.copyWith(roles: roles);
    } catch (e) {
      // Roles are optional
    }
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(ApiConfig.staff, data);
      await fetchStaff();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put('${ApiConfig.staff}/$id', data);
      await fetchStaff();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteStaff(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('${ApiConfig.staff}/$id');
      await fetchStaff();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
