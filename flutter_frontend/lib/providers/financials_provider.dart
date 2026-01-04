import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'],
      date: DateTime.parse(json['date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Invoice {
  final String id;
  final String? bookingId;
  final double amount;
  final String status;
  final DateTime createdAt;

  Invoice({
    required this.id,
    this.bookingId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      bookingId: json['booking_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RevenueStats {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  RevenueStats({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
    );
  }
}

class FinancialsState {
  final List<Expense> expenses;
  final List<Invoice> invoices;
  final RevenueStats? stats;
  final bool isLoading;
  final String? error;

  FinancialsState({
    this.expenses = const [],
    this.invoices = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  FinancialsState copyWith({
    List<Expense>? expenses,
    List<Invoice>? invoices,
    RevenueStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return FinancialsState(
      expenses: expenses ?? this.expenses,
      invoices: invoices ?? this.invoices,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final financialsProvider = StateNotifierProvider<FinancialsNotifier, FinancialsState>((ref) {
  final api = ref.read(apiServiceProvider);
  return FinancialsNotifier(api);
});

class FinancialsNotifier extends StateNotifier<FinancialsState> {
  final ApiService _api;

  FinancialsNotifier(this._api) : super(FinancialsState());

  Future<void> fetchExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getList('${ApiConfig.financials}/expenses');
      final expenses = response.map((json) => Expense.fromJson(json)).toList();
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await _api.getList('${ApiConfig.financials}/invoices');
      final invoices = response.map((json) => Invoice.fromJson(json)).toList();
      state = state.copyWith(invoices: invoices);
    } catch (e) {
      // Invoices optional
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await _api.get('${ApiConfig.financials}/stats');
      final stats = RevenueStats.fromJson(response);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats optional
    }
  }

  Future<void> createExpense(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('${ApiConfig.financials}/expenses', data);
      await fetchExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
