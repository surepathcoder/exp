import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/transfer.dart';
import '../models/notification.dart';
import '../models/project.dart';
import '../models/audit_log.dart';
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
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      return User.fromJson(response.data);
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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {'email': email});
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword(String email, String token, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'token': token,
        'new_password': newPassword,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.put('/settings/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Expenses
  Future<List<Expense>> getExpenses({
    String? startDate,
    String? endDate,
    List<String>? categories,
    int? userId,
    String? search,
    double? minAmount,
    double? maxAmount,
    String? status,
    List<String>? projects,
    int? projectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) {
        queryParams['category'] = categories;
      }
      if (projects != null && projects.isNotEmpty) {
        queryParams['project'] = projects;
      }
      if (projectId != null) {
        queryParams['project_id'] = projectId;
      }
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minAmount != null) queryParams['min_amount'] = minAmount;
      if (maxAmount != null) queryParams['max_amount'] = maxAmount;
      if (status != null && status != 'all') queryParams['status'] = status;

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

  Future<String> uploadReceipt(List<int> bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post('/expenses/upload-receipt', data: formData);
      return response.data['photo_url'];
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

  Future<List<int>> downloadExpensesCsv({
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
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) {
        queryParams['category'] = categories;
      }
      if (projects != null && projects.isNotEmpty) {
        queryParams['project'] = projects;
      }
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minAmount != null) queryParams['min_amount'] = minAmount;
      if (maxAmount != null) queryParams['max_amount'] = maxAmount;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response = await _dio.get(
        '/expenses/export/csv',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> downloadExpensesPdf({
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
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) {
        queryParams['category'] = categories;
      }
      if (projects != null && projects.isNotEmpty) {
        queryParams['project'] = projects;
      }
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minAmount != null) queryParams['min_amount'] = minAmount;
      if (maxAmount != null) queryParams['max_amount'] = maxAmount;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response = await _dio.get(
        '/expenses/export/pdf',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Incomes
  Future<List<Income>> getIncomes({
    String? startDate,
    String? endDate,
    String? source,
    int? userId,
    List<String>? projects,
    int? projectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (source != null) queryParams['source'] = source;
      if (userId != null) queryParams['user_id'] = userId;
      if (projects != null && projects.isNotEmpty) {
        queryParams['project'] = projects;
      }
      if (projectId != null) {
        queryParams['project_id'] = projectId;
      }

      final response = await _dio.get('/incomes', queryParameters: queryParams);
      return (response.data as List).map((e) => Income.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Income> createIncome(Income income) async {
    try {
      final response = await _dio.post('/incomes', data: income.toJson());
      return Income.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Income> updateIncome(int id, Income income) async {
    try {
      final response = await _dio.put('/incomes/$id', data: income.toJson());
      return Income.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _dio.delete('/incomes/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Projects
  Future<List<Project>> getProjects({bool? activeOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (activeOnly != null) queryParams['active_only'] = activeOnly;
      final response = await _dio.get('/projects', queryParameters: queryParams);
      return (response.data as List).map((p) => Project.fromJson(p)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Project> createProject(Project project) async {
    try {
      final response = await _dio.post('/projects', data: project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Project> updateProject(int id, Project project) async {
    try {
      final response = await _dio.put('/projects/$id', data: project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _dio.delete('/projects/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProjectSummary(int id) async {
    try {
      final response = await _dio.get('/projects/$id/summary');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardProjects() async {
    try {
      final response = await _dio.get('/dashboard/projects');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Transfers
  Future<List<Transfer>> getTransfers({
    String? startDate,
    String? endDate,
    int? userId,
    List<String>? projects,
    int? projectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (userId != null) queryParams['user_id'] = userId;
      if (projects != null && projects.isNotEmpty) {
        queryParams['project'] = projects;
      }
      if (projectId != null) {
        queryParams['project_id'] = projectId;
      }

      final response = await _dio.get('/transfers', queryParameters: queryParams);
      return (response.data as List).map((e) => Transfer.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transfer> createTransfer(Transfer transfer) async {
    try {
      final response = await _dio.post('/transfers', data: transfer.toJson());
      return Transfer.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transfer> updateTransfer(int id, Transfer transfer) async {
    try {
      final response = await _dio.put('/transfers/$id', data: transfer.toJson());
      return Transfer.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTransfer(int id) async {
    try {
      await _dio.delete('/transfers/$id');
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

  Future<User> updateUserApproval(int id, bool isApproved) async {
    try {
      final response = await _dio.put('/users/$id/approval', data: {'is_approved': isApproved});
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

  // Audit Logs
  Future<List<AuditLog>> getAuditLogs({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/settings/audit-logs',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return (response.data as List).map((e) => AuditLog.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard
  Future<Map<String, double>> getRates() async {
    try {
      final response = await _dio.get('/dashboard/rates');
      return Map<String, double>.from(response.data.map((k, v) => MapEntry(k, (v as num).toDouble())));
    } catch (e) {
      throw _handleError(e);
    }
  }

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

  // Notifications API
  Future<List<AppNotification>> getNotifications({
    bool? isRead,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }
      final response = await _dio.get('/notifications', queryParameters: queryParams);
      return (response.data as List)
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['count'] as int;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead({int? notificationId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (notificationId != null) {
        queryParams['notification_id'] = notificationId;
      }
      await _dio.put('/notifications/read', queryParameters: queryParams);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendAdminBroadcast({
    required String title,
    required String message,
    String type = 'info',
    String priority = 'normal',
    int? targetUserId,
    bool isBroadcast = false,
  }) async {
    try {
      await _dio.post('/admin/notifications', data: {
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'target_user_id': targetUserId,
        'is_broadcast': isBroadcast,
      });
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
