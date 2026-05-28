import 'package:flutter_riverpod/legacy.dart';
import '../models/income.dart';
import '../services/api_service.dart';

class IncomeState {
  final List<Income> incomes;
  final bool isLoading;
  final String? error;

  IncomeState({
    this.incomes = const [],
    this.isLoading = false,
    this.error,
  });

  IncomeState copyWith({
    List<Income>? incomes,
    bool? isLoading,
    String? error,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IncomeNotifier extends StateNotifier<IncomeState> {
  final ApiService _apiService;

  IncomeNotifier(this._apiService) : super(IncomeState());

  Future<void> fetchIncomes({
    String? startDate,
    String? endDate,
    String? source,
    int? userId,
    List<String>? projects,
    int? projectId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final incomes = await _apiService.getIncomes(
        startDate: startDate,
        endDate: endDate,
        source: source,
        userId: userId,
        projects: projects,
        projectId: projectId,
      );
      state = state.copyWith(incomes: incomes, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addIncome(Income income) async {
    state = state.copyWith(isLoading: true);
    try {
      final newIncome = await _apiService.createIncome(income);
      state = state.copyWith(
        incomes: [newIncome, ...state.incomes],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateIncome(int id, Income income) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedIncome = await _apiService.updateIncome(id, income);
      state = state.copyWith(
        incomes: state.incomes.map((e) => e.id == id ? updatedIncome : e).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteIncome(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteIncome(id);
      state = state.copyWith(
        incomes: state.incomes.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final incomeProvider = StateNotifierProvider<IncomeNotifier, IncomeState>((ref) {
  return IncomeNotifier(ref.watch(apiServiceProvider));
});
