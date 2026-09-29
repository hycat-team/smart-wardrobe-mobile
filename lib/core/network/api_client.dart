import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

typedef ForcedLogoutCallback = void Function();

class ApiClient {
  final Dio dio;
  final SecureStorageService storage;
  ForcedLogoutCallback? onForcedLogout;

  static ForcedLogoutCallback? onGlobalForcedLogout;
  static Future<String?>? _globalRefreshFuture;

  ApiClient({Dio? dioClient, SecureStorageService? storageService})
      : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 60),
                extra: {
                  'withCredentials': true, // Sends cookies across origins on Web
                },
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (!kIsWeb) 'Accept-Encoding': 'identity',
                },
              ),
            ),
        storage = storageService ?? SecureStorageService() {
    _setupInterceptors();
  }

  @visibleForTesting
  static void resetGlobalState() {
    _globalRefreshFuture = null;
    onGlobalForcedLogout = null;
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isLogout = options.path.contains('/auth/logout');
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty && token != 'web_session_active') {
            options.headers['Authorization'] = 'Bearer $token';
            if (kIsWeb) {
              // Khi mobile app đã có Bearer token hợp lệ, tắt withCredentials
              // để browser không gửi kèm cookie HttpOnly cũ của tài khoản trước đó,
              // tránh việc Backend ưu tiên cookie đè lên Bearer token gây lỗi đa tài khoản.
              // NGOẠI TRỪ khi gọi /auth/logout: cần bật withCredentials = true để browser
              // gửi cookie và xử lý Set-Cookie xóa cookie HttpOnly từ Backend.
              options.extra['withCredentials'] = isLogout;
            }
          } else if (kIsWeb) {
            if (token == 'web_session_active' || isLogout) {
              options.extra['withCredentials'] = true;
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            // Không tự động refresh cho các endpoint đăng nhập / xác thực đặc thù
            if (path.contains('/auth/login') ||
                path.contains('/auth/google') ||
                path.contains('/auth/refresh-token') ||
                path.contains('/auth/logout')) {
              return handler.next(error);
            }

            // Chỉ retry 1 lần duy nhất để tránh lặp vô tận
            if (error.requestOptions.extra['isRetry'] == true) {
              return handler.next(error);
            }

            // Phiên cookie web (luồng redirect) không có refresh token:
            // hết phiên thì đăng xuất thẳng, không thử refresh.
            final currentToken = await storage.getToken();
            if (currentToken == 'web_session_active') {
              _triggerForcedLogout();
              return handler.next(error);
            }

            try {
              final newAccessToken = await _performSingleFlightRefresh();
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';
                options.extra['isRetry'] = true;

                final response = await dio.fetch(options);
                return handler.resolve(response);
              } else {
                _triggerForcedLogout();
                return handler.next(error);
              }
            } catch (_) {
              _triggerForcedLogout();
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performSingleFlightRefresh() async {
    if (_globalRefreshFuture != null) {
      return _globalRefreshFuture!;
    }

    final future = _performRefreshToken();
    _globalRefreshFuture = future;
    try {
      return await future;
    } finally {
      if (_globalRefreshFuture == future) {
        _globalRefreshFuture = null;
      }
    }
  }

  Future<String?> _performRefreshToken() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl.isNotEmpty ? dio.options.baseUrl : AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (!kIsWeb) 'Accept-Encoding': 'identity',
        },
      ),
    );

    try {
      final response = await refreshDio.post(
        AppConstants.refreshTokenEndpoint,
        data: {
          'oldRefreshToken': refreshToken,
          'deviceName': kIsWeb ? 'Web' : 'Android',
        },
      );

      final dynamic resData = response.data;
      Map<String, dynamic>? dataMap;
      if (resData is Map<String, dynamic>) {
        dataMap = resData;
      } else if (resData is Map) {
        dataMap = Map<String, dynamic>.from(resData);
      }

      final dynamic nestedData = dataMap?['data'];
      Map<String, dynamic>? tokenMap;
      if (nestedData is Map<String, dynamic>) {
        tokenMap = nestedData;
      } else if (nestedData is Map) {
        tokenMap = Map<String, dynamic>.from(nestedData);
      } else {
        tokenMap = dataMap;
      }

      final newAccessToken = tokenMap?['accessToken']?.toString() ??
          tokenMap?['token']?.toString() ??
          tokenMap?['access_token']?.toString();
      final newRefreshToken = tokenMap?['refreshToken']?.toString() ??
          tokenMap?['refresh_token']?.toString();

      if (newAccessToken != null &&
          newAccessToken.isNotEmpty &&
          newAccessToken.split('.').length == 3) {
        await storage.saveToken(newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await storage.saveRefreshToken(newRefreshToken);
        }
        return newAccessToken;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _triggerForcedLogout() {
    onForcedLogout?.call();
    onGlobalForcedLogout?.call();
  }
}
