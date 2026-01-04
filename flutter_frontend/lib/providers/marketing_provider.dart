import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketing.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MarketingState {
  final Branding? branding;
  final LandingPage? landingPage;
  final bool isLoading;
  final String? error;

  MarketingState({
    this.branding,
    this.landingPage,
    this.isLoading = false,
    this.error,
  });

  MarketingState copyWith({
    Branding? branding,
    LandingPage? landingPage,
    bool? isLoading,
    String? error,
  }) {
    return MarketingState(
      branding: branding ?? this.branding,
      landingPage: landingPage ?? this.landingPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final marketingProvider = StateNotifierProvider<MarketingNotifier, MarketingState>((ref) {
  final api = ref.read(apiServiceProvider);
  return MarketingNotifier(api);
});

class MarketingNotifier extends StateNotifier<MarketingState> {
  final ApiService _api;

  MarketingNotifier(this._api) : super(MarketingState());

  Future<void> fetchMarketingData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final brandingData = await _api.get(ApiConfig.branding);
      final landingData = await _api.get(ApiConfig.landingPage);
      
      state = state.copyWith(
        branding: Branding.fromJson(brandingData),
        landingPage: LandingPage.fromJson(landingData),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBranding(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(ApiConfig.branding, data);
      await fetchMarketingData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateLandingPage(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(ApiConfig.landingPage, data);
      await fetchMarketingData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleLive(bool isLive) async {
    // Only update the is_live field
    final currentLp = state.landingPage;
    if (currentLp == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = currentLp.toJson();
      data['is_live'] = isLive;
      await _api.put(ApiConfig.landingPage, data);
      await fetchMarketingData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
