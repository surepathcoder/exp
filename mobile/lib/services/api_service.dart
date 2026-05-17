import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/expense.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
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

  // Auth
  Future<Map<String, dynamic>> login(String email) async {
    try {
      final response = await _dio.post('/auth/login', data: {'email': email});
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Expenses
  Future<List<Expense>> getExpenses({
    String? startDate,
    String? endDate,
    String? category,
    int? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (category != null) queryParams['category'] = category;
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _dio.get('/expenses', queryParameters: queryParams);
      return (response.data as List).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await _dio.post('/expenses', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    try {
      final response = await _dio.put('/expenses/$id', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/expenses/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Users
  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      return (response.data as List).map((e) => User.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateUserRole(int id, String role) async {
    try {
      final response = await _dio.put('/users/$id/role', data: {'role': role});
      return User.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/users/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard
  Future<Map<String, double>> getBalance() async {
    try {
      final response = await _dio.get('/dashboard/balance');
      return Map<String, double>.from(response.data.map((k, v) => MapEntry(k, (v as num).toDouble())));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<double> getSelfReceiptPercentage() async {
    try {
      final response = await _dio.get('/dashboard/self-receipt-percentage');
      return (response.data['percentage'] as num).toDouble();
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return error.response?.data['detail'] ?? 'An error occurred';
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}

final apiServiceProvider = Provider((ref) => ApiService());
