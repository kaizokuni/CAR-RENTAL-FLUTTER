import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

// Cars state
class CarsState {
  final List<Car> cars;
  final bool isLoading;
  final String? error;

  CarsState({
    this.cars = const [],
    this.isLoading = false,
    this.error,
  });

  CarsState copyWith({
    List<Car>? cars,
    bool? isLoading,
    String? error,
  }) {
    return CarsState(
      cars: cars ?? this.cars,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final carsProvider = StateNotifierProvider<CarsNotifier, CarsState>((ref) {
  final api = ref.read(apiServiceProvider);
  return CarsNotifier(api);
});

class CarsNotifier extends StateNotifier<CarsState> {
  final ApiService _api;

  CarsNotifier(this._api) : super(CarsState());

  Future<void> fetchCars() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList(ApiConfig.cars);
      final cars = response.map((json) => Car.fromJson(json)).toList();
      state = state.copyWith(cars: cars, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCar(Map<String, dynamic> carData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(ApiConfig.cars, carData);
      await fetchCars();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateCar(String id, Map<String, dynamic> carData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put('${ApiConfig.cars}/$id', carData);
      await fetchCars();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteCar(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('${ApiConfig.cars}/$id');
      await fetchCars();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Stats providers
final availableCarsCountProvider = Provider<int>((ref) {
  final cars = ref.watch(carsProvider).cars;
  return cars.where((c) => c.status.toLowerCase() == 'available').length;
});

final rentedCarsCountProvider = Provider<int>((ref) {
  final cars = ref.watch(carsProvider).cars;
  return cars.where((c) => c.status.toLowerCase() == 'rented').length;
});

final maintenanceCarsCountProvider = Provider<int>((ref) {
  final cars = ref.watch(carsProvider).cars;
  return cars.where((c) => c.status.toLowerCase() == 'maintenance').length;
});
