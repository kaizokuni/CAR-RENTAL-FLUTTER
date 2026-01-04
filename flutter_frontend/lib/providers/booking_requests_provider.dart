import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_request.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BookingRequestsState {
  final List<BookingRequest> requests;
  final bool isLoading;
  final String? error;
  final String? selectedStatus; // null = all, or 'pending', 'contacted', etc.

  const BookingRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  BookingRequestsState copyWith({
    List<BookingRequest>? requests,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    bool clearError = false,
  }) {
    return BookingRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  List<BookingRequest> get filteredRequests {
    if (selectedStatus == null || selectedStatus == 'all') {
      return requests;
    }
    return requests.where((req) => req.status == selectedStatus).toList();
  }
}

class BookingRequestsNotifier extends StateNotifier<BookingRequestsState> {
  final ApiService apiService;

  BookingRequestsNotifier(this.apiService) : super(const BookingRequestsState());

  Future<void> fetchBookingRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await apiService.getList(ApiConfig.bookingRequests);
      
      // getList now returns empty list for null/empty responses
      final requests = response
          .map((json) => BookingRequest.fromJson(json as Map<String, dynamic>))
          .toList();
      
      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await apiService.put(
        '${ApiConfig.bookingRequests}/$requestId/status',
        {'status': newStatus},
      );
      
      // Update local state optimistically
      final updatedRequests = state.requests.map((req) {
        if (req.id == requestId) {
          return req.copyWith(status: newStatus);
        }
        return req;
      }).toList();
      
      state = state.copyWith(
        requests: updatedRequests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await apiService.delete('${ApiConfig.bookingRequests}/$requestId');
      
      // Remove from local state
      final updatedRequests = state.requests
          .where((req) => req.id != requestId)
          .toList();
      
      state = state.copyWith(
        requests: updatedRequests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final bookingRequestsProvider =
    StateNotifierProvider<BookingRequestsNotifier, BookingRequestsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BookingRequestsNotifier(apiService);
});
