import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AdminStats {
  final int totalTenants;
  final int activeTenants;
  final int newThisMonth;

  AdminStats({
    this.totalTenants = 0,
    this.activeTenants = 0,
    this.newThisMonth = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalTenants: json['total_tenants'] ?? 0,
      activeTenants: json['active_tenants'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
    );
  }
}

class AdminState {
  final List<Tenant> tenants;
  final AdminStats? stats;
  final bool isLoading;
  final String? error;

  AdminState({
    this.tenants = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<Tenant>? tenants,
    AdminStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      tenants: tenants ?? this.tenants,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final api = ref.read(apiServiceProvider);
  return AdminNotifier(api);
});

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiService _api;

  AdminNotifier(this._api) : super(AdminState());

  Future<void> fetchTenants() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList(ApiConfig.adminTenants);
      // Handle null or empty response
      if (response == null) {
        state = state.copyWith(tenants: [], isLoading: false);
        return;
      }
      final tenants = response.map((json) => Tenant.fromJson(json)).toList();
      state = state.copyWith(tenants: tenants, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await _api.get(ApiConfig.adminStats);
      final stats = AdminStats.fromJson(response);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats are optional, don't fail the whole page
    }
  }

  Future<void> updateSubscription(String tenantId, String tier) async {
    try {
      await _api.put(
        '${ApiConfig.adminTenants}/$tenantId/subscription',
        {'subscription_tier': tier},
      );
      await fetchTenants();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> impersonateTenant(String tenantId) async {
    final response = await _api.post(
      '${ApiConfig.adminTenants}/$tenantId/impersonate',
      {},
    );
    return response['token'] as String;
  }
}
