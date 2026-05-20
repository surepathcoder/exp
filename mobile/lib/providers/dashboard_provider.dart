import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../utils/currency_converter.dart';

class DashboardState {
  final Map<String, double> balances;
  final double selfReceiptPercentage;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.balances = const {'USD': 0, 'TZS': 0, 'KES': 0},
    this.selfReceiptPercentage = 0.0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    Map<String, double>? balances,
    double? selfReceiptPercentage,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      balances: balances ?? this.balances,
      selfReceiptPercentage: selfReceiptPercentage ?? this.selfReceiptPercentage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;

  DashboardNotifier(this._apiService) : super(DashboardState());

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true);
    try {
      final rates = await _apiService.getRates();
      CurrencyConverter.updateRates(rates);

      final balances = await _apiService.getBalance();
      final percentage = await _apiService.getSelfReceiptPercentage();
      
      state = state.copyWith(
        balances: balances,
        selfReceiptPercentage: percentage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(apiServiceProvider));
});
