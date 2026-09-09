import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService storage;

  ApiClient({Dio? dioClient, SecureStorageService? storageService})
      : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
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

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty && token != 'web_session_active') {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Auto token refresh can be implemented here
          }
          return handler.next(error);
        },
      ),
    );
  }
}
