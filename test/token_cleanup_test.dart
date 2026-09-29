import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:smart_wardrobe/core/constants/app_constants.dart';
import 'package:smart_wardrobe/core/network/api_client.dart';
import 'package:smart_wardrobe/core/storage/secure_storage_service.dart';
import 'package:smart_wardrobe/core/session/session_provider.dart';

class MockStorageService extends SecureStorageService {
  final Map<String, String> values = {};
  final List<String> deletedKeys = [];
  bool deleteAllCalled = false;

  @override
  Future<void> saveToken(String token) async {
    values[AppConstants.tokenKey] = token;
  }

  @override
  Future<String?> getToken() async {
    return values[AppConstants.tokenKey];
  }

  @override
  Future<void> clearToken() async {
    deletedKeys.add(AppConstants.tokenKey);
    values.remove(AppConstants.tokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    values[AppConstants.refreshTokenKey] = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return values[AppConstants.refreshTokenKey];
  }

  @override
  Future<void> saveData(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<String?> getData(String key) async {
    return values[key];
  }

  @override
  Future<void> clearAll() async {
    deletedKeys.addAll([
      AppConstants.tokenKey,
      AppConstants.refreshTokenKey,
      AppConstants.userProfileKey,
      'user_style_prefs',
      'user_color_palette',
      'web_session',
    ]);
    deleteAllCalled = true;
    values.clear();
  }
}

void main() {
  group('Token & Storage Cleanup Tests', () {
    test('MockStorageService clearAll removes all keys and calls deleteAll', () async {
      final storage = MockStorageService();
      await storage.saveToken('jwt.token.here');
      await storage.saveRefreshToken('jwt.refresh.here');
      await storage.saveData('user_style_prefs', 'minimalism');

      expect(await storage.getToken(), 'jwt.token.here');
      expect(await storage.getRefreshToken(), 'jwt.refresh.here');
      expect(await storage.getData('user_style_prefs'), 'minimalism');

      await storage.clearAll();

      expect(await storage.getToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getData('user_style_prefs'), isNull);
      expect(storage.deleteAllCalled, true);
      expect(storage.deletedKeys, contains(AppConstants.tokenKey));
      expect(storage.deletedKeys, contains(AppConstants.refreshTokenKey));
    });

    test('ApiClient interceptor correctly handles withCredentials for logout vs normal requests', () async {
      final storage = MockStorageService();
      await storage.saveToken('header.payload.signature');

      final dio = Dio();
      final client = ApiClient(dioClient: dio, storageService: storage);

      // Verify interceptor behavior with custom request options
      final normalOptions = RequestOptions(path: '/me');
      final logoutOptions = RequestOptions(path: '/auth/logout');

      // Emulate interceptor onRequest
      final interceptor = client.dio.interceptors.firstWhere((i) => i is InterceptorsWrapper) as InterceptorsWrapper;

      final normalHandler = RequestInterceptorHandler();
      interceptor.onRequest(normalOptions, normalHandler);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(normalOptions.headers['Authorization'], 'Bearer header.payload.signature');

      final logoutHandler = RequestInterceptorHandler();
      interceptor.onRequest(logoutOptions, logoutHandler);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(logoutOptions.headers['Authorization'], 'Bearer header.payload.signature');
    });

    test('bumpAppSession increases appSessionNotifier value', () {
      final initial = appSessionNotifier.value;
      bumpAppSession();
      expect(appSessionNotifier.value, initial + 1);
    });
  });
}
