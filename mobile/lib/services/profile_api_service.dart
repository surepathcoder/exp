import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ProfileApiService {
  late final Dio _dio;

  ProfileApiService() {
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

  Future<User> updateProfile(String name, String email) async {
    try {
      final response = await _dio.put('/users/me', data: {
        'name': name,
        'email': email,
      });
      return User.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw e.response?.data['detail'] ?? 'An error occurred';
      }
      throw e.toString();
    }
  }
}

final profileApiProvider = Provider((ref) => ProfileApiService());
