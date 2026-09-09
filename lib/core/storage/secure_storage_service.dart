import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  static final Map<String, String> _memoryFallback = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'smart_wardrobe',
                publicKey: 'smart_wardrobe_vault',
              ),
            );

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {
      _memoryFallback[AppConstants.tokenKey] = token;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _memoryFallback[AppConstants.tokenKey];
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (_) {
      _memoryFallback[AppConstants.refreshTokenKey] = token;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: AppConstants.refreshTokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _memoryFallback[AppConstants.refreshTokenKey];
  }

  Future<void> saveData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _memoryFallback[key] = value;
    }
  }

  Future<String?> getData(String key) async {
    try {
      final data = await _storage.read(key: key);
      if (data != null && data.isNotEmpty) return data;
    } catch (_) {}
    return _memoryFallback[key];
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    _memoryFallback.clear();
  }
}
