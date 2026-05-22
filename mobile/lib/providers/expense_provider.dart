import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;

  ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ApiService _apiService;

  ExpenseNotifier(this._apiService) : super(ExpenseState());

  Future<void> fetchExpenses({
    String? startDate,
    String? endDate,
    List<String>? categories,
    int? userId,
    String? search,
    double? minAmount,
    double? maxAmount,
    String? status,
    List<String>? projects,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final expenses = await _apiService.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        userId: userId,
        search: search,
        minAmount: minAmount,
        maxAmount: maxAmount,
        status: status,
        projects: projects,
      );
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addExpense(Expense expense) async {
    state = state.copyWith(isLoading: true);
    try {
      final newExpense = await _apiService.createExpense(expense);
      state = state.copyWith(
        expenses: [newExpense, ...state.expenses],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateExpense(int id, Expense expense) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedExpense = await _apiService.updateExpense(id, expense);
      state = state.copyWith(
        expenses: state.expenses.map((e) => e.id == id ? updatedExpense : e).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteExpense(id);
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(ref.watch(apiServiceProvider));
});
