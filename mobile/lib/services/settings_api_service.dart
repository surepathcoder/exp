import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/system_settings.dart';
import '../models/category.dart';
import '../models/audit_log.dart';
import '../models/system_stats.dart';
import '../models/user.dart';
import 'storage_service.dart';

class SettingsApiService {
  late final Dio _dio;

  SettingsApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // System Settings
  Future<SystemSettings> getSettings() async {
    try {
      final r = await _dio.get('/settings');
      return SystemSettings.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  Future<SystemSettings> updateSettings(Map<String, dynamic> data) async {
    try {
      final r = await _dio.put('/settings', data: data);
      return SystemSettings.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  // Categories
  Future<List<AppCategory>> getCategories({bool all = false}) async {
    try {
      final path = all ? '/settings/categories/all' : '/settings/categories';
      final r = await _dio.get(path);
      return (r.data as List).map((e) => AppCategory.fromJson(e)).toList();
    } catch (e) {
      throw _err(e);
    }
  }

  Future<AppCategory> createCategory(String name, int sortOrder) async {
    try {
      final r = await _dio.post('/settings/categories', data: {
        'name': name, 'sort_order': sortOrder,
      });
      return AppCategory.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  Future<AppCategory> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put('/settings/categories/$id', data: data);
      return AppCategory.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/settings/categories/$id');
    } catch (e) {
      throw _err(e);
    }
  }

  // User Management
  Future<User> createUser(String name, String email, String password, String role) async {
    try {
      final r = await _dio.post('/settings/users', data: {
        'name': name, 'email': email, 'password': password, 'role': role,
      });
      return User.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      await _dio.put('/settings/users/$userId/reset-password', data: {
        'new_password': newPassword,
      });
    } catch (e) {
      throw _err(e);
    }
  }

  Future<void> changePassword(String current, String newPwd) async {
    try {
      await _dio.put('/settings/change-password', data: {
        'current_password': current, 'new_password': newPwd,
      });
    } catch (e) {
      throw _err(e);
    }
  }

  // Stats & Audit
  Future<SystemStats> getStats() async {
    try {
      final r = await _dio.get('/settings/stats');
      return SystemStats.fromJson(r.data);
    } catch (e) {
      throw _err(e);
    }
  }

  Future<List<AuditLog>> getAuditLogs({int limit = 50, int offset = 0}) async {
    try {
      final r = await _dio.get('/settings/audit-logs', queryParameters: {
        'limit': limit, 'offset': offset,
      });
      return (r.data as List).map((e) => AuditLog.fromJson(e)).toList();
    } catch (e) {
      throw _err(e);
    }
  }

  String _err(dynamic error) {
    if (error is DioException && error.response != null) {
      return error.response?.data['detail'] ?? 'An error occurred';
    }
    if (error is DioException) return error.message ?? 'Network error';
    return error.toString();
  }
}

final settingsApiProvider = Provider((ref) => SettingsApiService());
