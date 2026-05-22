import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/settings_api_service.dart';

class CategoryState {
  final List<AppCategory> categories;
  final bool isLoading;
  final String? error;

  CategoryState({this.categories = const [], this.isLoading = false, this.error});

  Map<String, AppCategory> get categoriesByName => {
    for (var cat in categories) cat.name: cat
  };

  CategoryState copyWith({
    List<AppCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final SettingsApiService _api;

  CategoryNotifier(this._api) : super(CategoryState());

  Future<void> fetchCategories({bool all = true}) async {
    state = state.copyWith(isLoading: true);
    try {
      final cats = await _api.getCategories(all: all);
      state = state.copyWith(categories: cats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createCategory(
    String name,
    int sortOrder, {
    String color = '#9E9E9E',
    String? icon,
    String type = 'expense',
  }) async {
    try {
      await _api.createCategory(name, sortOrder, color: color, icon: icon, type: type);
      await fetchCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateCategory(id, data);
      await fetchCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _api.deleteCategory(id);
      await fetchCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reorderCategories(List<Map<String, dynamic>> items) async {
    try {
      await _api.reorderCategories(items);
      // Wait for fetch to ensure local state has correct db ordering
      await fetchCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref.watch(settingsApiProvider));
});
