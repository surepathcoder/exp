import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ReportsApiService {
  late final Dio _dio;

  ReportsApiService() {
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

  Future<Map<String, dynamic>> getReportsPreview({
    required String reportType,
    String? startDate,
    String? endDate,
    List<String>? categories,
    int? userId,
    List<String>? projects,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'report_type': reportType,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) queryParams['category'] = categories;
      if (projects != null && projects.isNotEmpty) queryParams['project'] = projects;
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('/reports/preview', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> downloadReportsPdf({
    required String reportType,
    String? startDate,
    String? endDate,
    List<String>? categories,
    int? userId,
    List<String>? projects,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'report_type': reportType,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) queryParams['category'] = categories;
      if (projects != null && projects.isNotEmpty) queryParams['project'] = projects;
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/reports/export/pdf',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> downloadReportsCsv({
    required String reportType,
    String? startDate,
    String? endDate,
    List<String>? categories,
    int? userId,
    List<String>? projects,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'report_type': reportType,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (categories != null && categories.isNotEmpty) queryParams['category'] = categories;
      if (projects != null && projects.isNotEmpty) queryParams['project'] = projects;
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/reports/export/csv',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
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

final reportsApiServiceProvider = Provider((ref) => ReportsApiService());
