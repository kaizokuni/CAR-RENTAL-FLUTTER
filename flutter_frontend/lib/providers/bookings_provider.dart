import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BookingsState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final api = ref.read(apiServiceProvider);
  return BookingsNotifier(api);
});

class BookingsNotifier extends StateNotifier<BookingsState> {
  final ApiService _api;

  BookingsNotifier(this._api) : super(BookingsState());

  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList(ApiConfig.bookings);
      final bookings = response.map((json) => Booking.fromJson(json)).toList();
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(ApiConfig.bookings, bookingData);
      await fetchBookings();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String id, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put('${ApiConfig.bookings}/$id/status', {'status': status});
      await fetchBookings();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Stats
final activeBookingsCountProvider = Provider<int>((ref) {
  final bookings = ref.watch(bookingsProvider).bookings;
  return bookings.where((b) => 
    b.status.toLowerCase() == 'active' || 
    b.status.toLowerCase() == 'confirmed'
  ).length;
});
