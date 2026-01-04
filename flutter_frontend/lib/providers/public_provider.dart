import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/car.dart';
import '../models/marketing.dart';

class PublicState {
  final Branding? branding;
  final LandingPage? landingPage;
  final List<Car> cars;
  final bool isLoading;
  final String? error;

  PublicState({
    this.branding,
    this.landingPage,
    this.cars = const [],
    this.isLoading = false,
    this.error,
  });

  PublicState copyWith({
    Branding? branding,
    LandingPage? landingPage,
    List<Car>? cars,
    bool? isLoading,
    String? error,
  }) {
    return PublicState(
      branding: branding ?? this.branding,
      landingPage: landingPage ?? this.landingPage,
      cars: cars ?? this.cars,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final publicProvider = StateNotifierProvider<PublicNotifier, PublicState>((ref) {
  final api = ref.read(apiServiceProvider);
  return PublicNotifier(api);
});

class PublicNotifier extends StateNotifier<PublicState> {
  final ApiService _api;

  PublicNotifier(this._api) : super(PublicState());

  Future<void> fetchLandingData(String subdomain) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use public endpoints
      final landingData = await _api.get('${ApiConfig.publicLanding}/$subdomain');
      // The branding might be included in landingData or fetched separately
      // Backend shows GetPublicLandingBySubdomain returns LandingPage
      
      final carData = await _api.getList('${ApiConfig.publicCars}/$subdomain');
      final cars = carData.map((json) => Car.fromJson(json)).toList();

      state = state.copyWith(
        landingPage: LandingPage.fromJson(landingData),
        cars: cars,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitBookingRequest(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/api/v1/public/booking-request', data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
