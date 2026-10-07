import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
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
    } on DioException {
      // Cố tình KHÔNG bọc lại thành Exception chuỗi tiếng Việt.
      //
      // Spec 015 — FR-026/027/428: `checkAuthStatus()` phải phân biệt được
      // "token bị máy chủ từ chối" (401/403 → xoá phiên) với "lỗi tạm thời" (mất
      // mạng, timeout, 5xx → giữ phiên). Bọc vào Exception sẽ xoá mất mã trạng thái
      // HTTP, khiến hai nhánh này không phân biệt được và mọi người dùng có phiên hợp
      // lệ đều bị đá ra màn đăng nhập chỉ vì sự cố mạng tạm thời.
      rethrow;
    }
  }

  Future<GoogleSignInOutcome> loginWithGoogle(
    String idToken, {
    String? deviceName,
  }) async {
    if (idToken.trim().isEmpty) {
      return GoogleSignInOutcome.cancelled();
    }

    final devName = deviceName ?? (kIsWeb ? 'Web' : 'Android');
    try {
      final response = await _apiClient.dio.post(
        AppConstants.googleAuthEndpoint,
        data: GoogleLoginRequest(
          idToken: idToken,
          deviceName: devName,
        ).toJson(),
        options: Options(
          headers: {
            if (!kIsWeb) 'Accept-Encoding': 'identity',
          },
        ),
      );

      final data = _parseResponseData(response.data);
      String? token;
      String? refreshToken;

      if (data != null) {
        final nestedData = _parseResponseData(data['data']) ?? data;
        token = nestedData['accessToken']?.toString() ??
            nestedData['token']?.toString() ??
            nestedData['access_token']?.toString();
        refreshToken = nestedData['refreshToken']?.toString() ??
            nestedData['refresh_token']?.toString();
      }

      if (token == null || token.isEmpty || token.split('.').length != 3) {
        await _storage.clearAll();
        return GoogleSignInOutcome.failed(
          errorCode: AuthErrorCode.invalidToken,
          customMessage: 'Phiên Google không hợp lệ, thử đăng nhập lại.',
        );
      }

      await _storage.saveToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(refreshToken);
      }

      final message = data?['message']?.toString();
      final nested = _parseResponseData(data?['data']) ?? data ?? {};
      final isLinked = nested['isLinked'] == true ||
          nested['linkedExistingAccount'] == true ||
          (message != null &&
              (message.toLowerCase().contains('liên kết') ||
                  message.toLowerCase().contains('linked')));

      return GoogleSignInOutcome.succeeded(
        linkedExistingAccount: isLinked,
        message: message,
      );
    } on DioException catch (e) {
      await _storage.clearAll();
      final statusCode = e.response?.statusCode;
      final rawData = _parseResponseData(e.response?.data);
      final rawError = rawData?['error']?.toString();
      final message = rawData?['message']?.toString() ??
          rawData?['detail']?.toString() ??
          (e.type == DioExceptionType.connectionError
              ? 'Không thể kết nối đến máy chủ.'
              : null);

      final errorCode = AuthErrorCode.fromErrorAndStatus(
        rawError: rawError,
        statusCode: statusCode,
        message: message,
      );

      return GoogleSignInOutcome.failed(
        errorCode: errorCode,
        customMessage: message ?? errorCode.defaultMessage,
      );
    } catch (e) {
      await _storage.clearAll();
      return GoogleSignInOutcome.failed(
        errorCode: AuthErrorCode.serverError,
        customMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<AuthTokenResponse> refreshSession(
    String oldRefreshToken, {
    String? deviceName,
  }) async {
    final devName = deviceName ?? (kIsWeb ? 'Web' : 'Android');
    final response = await _apiClient.dio.post(
      AppConstants.refreshTokenEndpoint,
      data: RefreshTokenRequest(
        oldRefreshToken: oldRefreshToken,
        deviceName: devName,
      ).toJson(),
      options: Options(
        headers: {
          if (!kIsWeb) 'Accept-Encoding': 'identity',
        },
      ),
    );

    final data = _parseResponseData(response.data);
    final nestedData = _parseResponseData(data?['data']) ?? data ?? {};
    final token = nestedData['accessToken']?.toString() ??
        nestedData['token']?.toString() ??
        nestedData['access_token']?.toString();
    final refreshToken = nestedData['refreshToken']?.toString() ??
        nestedData['refresh_token']?.toString();

    if (token == null || token.isEmpty || token.split('.').length != 3) {
      throw Exception('Làm mới phiên thất bại: token không hợp lệ.');
    }

    await _storage.saveToken(token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(refreshToken);
    }

    return AuthTokenResponse(
      accessToken: token,
      refreshToken: refreshToken,
      message: data?['message']?.toString(),
    );
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      final token = await _storage.getToken();
      await _apiClient.dio.post(
        AppConstants.logoutEndpoint,
        data: refreshToken != null && refreshToken.isNotEmpty
            ? {'refreshToken': refreshToken}
            : null,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty && token != 'web_session_active')
              'Authorization': 'Bearer $token',
            if (!kIsWeb) 'Accept-Encoding': 'identity',
          },
          extra: {
            if (kIsWeb) 'withCredentials': true,
          },
        ),
      );
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      if (token != null) await _storage.clearAll();
      return false;
    }
    // Web: phiên dựa trên cookie HttpOnly (luồng redirect) — đánh dấu bằng
    // placeholder; tính hợp lệ được xác nhận qua GET /me.
    if (token == 'web_session_active') return true;
    if (token.split('.').length != 3) {
      await _storage.clearAll();
      return false;
    }
    return true;
  }

  /// Web: hoàn tất phiên sau khi BE redirect về `/auth/callback`.
  /// BE đã đặt cookie HttpOnly; gọi `GET /me` (kèm cookie) để xác nhận rồi
  /// lưu placeholder `web_session_active`.
  Future<UserModel> completeWebSession() async {
    final user = await getCurrentUser();
    await _storage.saveToken('web_session_active');
    await _storage.saveData('web_session', '1');
    return user;
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
