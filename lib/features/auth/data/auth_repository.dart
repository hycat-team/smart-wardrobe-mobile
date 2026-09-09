import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Map<String, dynamic>? _parseResponseData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  Future<AuthTokenResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
        options: Options(
          headers: {
            if (!kIsWeb) 'Accept-Encoding': 'identity',
          },
        ),
      );

      final data = _parseResponseData(response.data);
      String? token;
      String? refreshToken;

      // 1. Extract token directly from JSON response body
      if (data != null) {
        final nestedData = _parseResponseData(data['data']) ?? data;
        token = nestedData['accessToken']?.toString() ??
            nestedData['token']?.toString() ??
            nestedData['access_token']?.toString();
        refreshToken = nestedData['refreshToken']?.toString() ??
            nestedData['refresh_token']?.toString();
      }

      // 2. Fallback: extract token from Set-Cookie headers
      final setCookieHeaders = response.headers['set-cookie'] ?? [];
      for (final cookie in setCookieHeaders) {
        if (token == null || token.isEmpty) {
          final match = RegExp(r'accessToken=([^;]+)').firstMatch(cookie);
          if (match != null) token = match.group(1);
        }
        if (refreshToken == null || refreshToken.isEmpty) {
          final match = RegExp(r'refreshToken=([^;]+)').firstMatch(cookie);
          if (match != null) refreshToken = match.group(1);
        }
      }

      // 3. Strict verification: must be a valid non-empty 3-part JWT
      if (token == null || token.isEmpty || token.split('.').length != 3) {
        await _storage.clearAll();
        throw Exception('Sai tài khoản hoặc mật khẩu.');
      }

      // 4. Save real tokens to secure storage
      await _storage.saveToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(refreshToken);
      }

      return AuthTokenResponse(
        accessToken: token,
        refreshToken: refreshToken,
        message: data?['message']?.toString(),
      );
    } on DioException catch (e) {
      await _storage.clearAll();
      throw Exception(_extractErrorMessage(e, 'Sai tài khoản hoặc mật khẩu.'));
    } catch (e) {
      await _storage.clearAll();
      rethrow;
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      await _apiClient.dio.post(
        '/auth/register',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Đăng ký thất bại'));
    }
  }

  Future<void> confirmRegisterOtp(String email, String otpCode) async {
    try {
      await _apiClient.dio.post(
        '/auth/register/confirm-otp',
        data: ConfirmRegisterOtpRequest(email: email, otpCode: otpCode).toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Xác thực mã OTP thất bại'));
    }
  }

  Future<void> resendRegisterOtp(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/register/resend-otp',
        data: ResendOtpRequest(email: email).toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể gửi lại mã OTP'));
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password',
        data: ForgotPasswordRequest(email: email).toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Yêu cầu khôi phục mật khẩu thất bại'));
    }
  }

  Future<void> confirmForgotPasswordOtp(String email, String otpCode) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password/confirm-otp',
        data: ConfirmForgotPasswordOtpRequest(email: email, otpCode: otpCode).toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Xác thực OTP quên mật khẩu không đúng'));
    }
  }

  Future<void> resetPassword(String newPassword, String confirmPassword) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: ResetPasswordRequest(
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ).toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Đặt lại mật khẩu thất bại'));
    }
  }

  Future<void> saveStylePreferences(List<String> styles, String palette) async {
    await _storage.saveData('user_style_prefs', styles.join(','));
    await _storage.saveData('user_color_palette', palette);
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/me');
      final data = _parseResponseData(response.data);
      final userData = _parseResponseData(data?['data']) ?? data ?? {};
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải thông tin cá nhân'));
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty || token == 'web_session_active' || token.split('.').length != 3) {
      if (token != null && token.isNotEmpty) {
        await _storage.clearAll();
      }
      return false;
    }
    return true;
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = _parseResponseData(e.response?.data);
    if (data != null) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
        return data['detail'].toString();
      }
      if (data['title'] != null && data['title'].toString().isNotEmpty) {
        return data['title'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        (e.message != null && e.message!.contains('XMLHttpRequest'))) {
      return 'Không thể kết nối đến máy chủ backend (vui lòng kiểm tra server).';
    }
    return e.message ?? fallback;
  }
}
