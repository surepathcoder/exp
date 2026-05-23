import 'package:flutter_riverpod/legacy.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  UserState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final ApiService _apiService;

  UserNotifier(this._apiService) : super(UserState());

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _apiService.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateUserRole(int userId, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _apiService.updateUserRole(userId, role);
      state = state.copyWith(
        users: state.users.map((u) => u.id == userId ? updatedUser : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteUser(int userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteUser(userId);
      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateUserApproval(int userId, bool isApproved) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _apiService.updateUserApproval(userId, isApproved);
      state = state.copyWith(
        users: state.users.map((u) => u.id == userId ? updatedUser : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(apiServiceProvider));
});
