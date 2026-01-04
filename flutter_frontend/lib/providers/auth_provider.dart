import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(AuthState()) {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        // Check if token is expired
        if (JwtDecoder.isExpired(token)) {
          await logout();
          return;
        }
        
        _api.setToken(token);
        final decoded = JwtDecoder.decode(token);
        final role = decoded['role'] as String?;
        
        state = state.copyWith(
          token: token,
          role: role,
          isLoading: false,
        );
        
        // Fetch user details
        await fetchUser();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      final token = response['token'] as String;
      final decoded = JwtDecoder.decode(token);
      final role = decoded['role'] as String?;

      // Store token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      _api.setToken(token);

      state = state.copyWith(
        token: token,
        role: role,
        isLoading: false,
      );

      // Fetch user details
      await fetchUser();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> fetchUser() async {
    try {
      final response = await _api.get(ApiConfig.me);
      
      final user = User.fromJson(response['user']);
      Tenant? tenant;
      if (response['tenant'] != null) {
        tenant = Tenant.fromJson(response['tenant']);
      }

      state = state.copyWith(
        user: user,
        tenant: tenant,
      );
    } catch (e) {
      // If fetching user fails with 401, logout
      if (e is ApiException && e.statusCode == 401) {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _api.setToken(null);
    state = AuthState();
  }

  bool hasSubscription(String minTier) {
    if (state.isSuperAdmin) return true;
    
    final currentTier = state.tenant?.subscriptionTier ?? 'normal';
    final tierLevels = {'normal': 1, 'pro': 2, 'premium': 3};
    
    return (tierLevels[currentTier] ?? 0) >= (tierLevels[minTier] ?? 0);
  }
}

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSuperAdmin;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentTenantProvider = Provider<Tenant?>((ref) {
  return ref.watch(authProvider).tenant;
});

class AuthState {
  final String? token;
  final String? role;
  final User? user;
  final Tenant? tenant;
  final bool isLoading;
  final String? error;

  AuthState({
    this.token,
    this.role,
    this.user,
    this.tenant,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null;
  bool get isSuperAdmin => role == 'super_admin';

  AuthState copyWith({
    String? token,
    String? role,
    User? user,
    Tenant? tenant,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      user: user ?? this.user,
      tenant: tenant ?? this.tenant,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
