import 'package:flutter_riverpod/legacy.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/profile_api_service.dart';
import '../utils/currency_converter.dart';


class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't preserve old errors
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final ProfileApiService _profileApiService;

  AuthNotifier(this._apiService, this._profileApiService) : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await storageService.getToken();
      if (token != null) {
        final user = await _apiService.getMe();
        state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
        _fetchRates();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      await storageService.deleteToken();
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.login(email, password);
      final token = response['token']['access_token'];
      final user = User.fromJson(response['user']);
      
      await storageService.saveToken(token);
      state = state.copyWith(user: user, isAuthenticated: true, isLoading: false);
      _fetchRates();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> _fetchRates() async {
    try {
      final rates = await _apiService.getRates();
      CurrencyConverter.updateRates(rates);
      if (rates['TZS'] == 2500.0 && rates['KES'] == 130.0) {
        await CurrencyConverter.fetchFallbackRates();
      }
    } catch (e) {
      await CurrencyConverter.fetchFallbackRates();
    }
  }

  Future<void> logout() async {
    await storageService.clearAll();
    state = AuthState();
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.register(name, email, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateProfile(String name, String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _profileApiService.updateProfile(name, email);
      state = state.copyWith(user: updatedUser, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(profileApiProvider),
  );
});
