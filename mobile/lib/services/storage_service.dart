import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: Constants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: Constants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: Constants.tokenKey);
  }

  Future<void> saveFavoriteFilters(String jsonStr) async {
    await _storage.write(key: Constants.favoriteFiltersKey, value: jsonStr);
  }

  Future<String?> getFavoriteFilters() async {
    return await _storage.read(key: Constants.favoriteFiltersKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final storageService = StorageService();
