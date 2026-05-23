import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/wallet.dart';
import 'storage_service.dart';

class WalletsApiService {
  late final Dio _dio;

  WalletsApiService() {
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

  Future<List<Wallet>> getWallets({bool includeArchived = false}) async {
    try {
      final response = await _dio.get(
        '/wallets',
        queryParameters: {'include_archived': includeArchived},
      );
      return (response.data as List).map((e) => Wallet.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Wallet> createWallet({
    required String name,
    required String type,
    required String currency,
    required double openingBalance,
    String icon = 'wallet',
    String color = '#3D1B5B',
  }) async {
    try {
      final response = await _dio.post('/wallets', data: {
        'name': name,
        'type': type,
        'currency': currency,
        'opening_balance': openingBalance,
        'icon': icon,
        'color': color,
      });
      return Wallet.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Wallet> updateWallet(int id, {
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (type != null) data['type'] = type;
      if (icon != null) data['icon'] = icon;
      if (color != null) data['color'] = color;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.put('/wallets/$id', data: data);
      return Wallet.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteWallet(int id) async {
    try {
      await _dio.delete('/wallets/$id');
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

final walletsApiServiceProvider = Provider((ref) => WalletsApiService());
