import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;

  CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final api = ref.read(apiServiceProvider);
  return CustomersNotifier(api);
});

class CustomersNotifier extends StateNotifier<CustomersState> {
  final ApiService _api;

  CustomersNotifier(this._api) : super(CustomersState());

  Future<void> fetchCustomers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList(ApiConfig.customers);
      final customers = response.map((json) => Customer.fromJson(json)).toList();
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCustomer(Map<String, dynamic> customerData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(ApiConfig.customers, customerData);
      await fetchCustomers();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final customersCountProvider = Provider<int>((ref) {
  return ref.watch(customersProvider).customers.length;
});
