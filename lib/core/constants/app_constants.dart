import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'Smart Wardrobe';

  // Cloudinary Cloud Name with fallback (--dart-define > .env > demo).
  static String get cloudinaryCloudName {
    const defined = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    if (defined.isNotEmpty) return defined;
    if (dotenv.isInitialized) {
      return dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'demo';
    }
    return 'demo';
  }

  // Base API URL with Android emulator support & .env loading.
  // Thứ tự ưu tiên: --dart-define (cho bản build CI/Vercel) > .env > localhost.
  static String get baseUrl {
    final url = _resolveBaseUrl();
    // Bản release bắt buộc trỏ tới endpoint HTTPS thật (spec 008, FR-023).
    // Fail-fast thay vì fallback im lặng về địa chỉ mẫu.
    if (kReleaseMode && (url.isEmpty || url.contains('[IP_ADDRESS]'))) {
      throw StateError(
        'API_BASE_URL chưa cấu hình cho bản release. '
        'Truyền --dart-define=API_BASE_URL=https://<prod>/api/v1 khi build.',
      );
    }
    return url;
  }

  static String _resolveBaseUrl() {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    const definedAndroidUrl = String.fromEnvironment('API_BASE_URL_ANDROID');
    if (dotenv.isInitialized) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          if (definedAndroidUrl.isNotEmpty) return definedAndroidUrl;
          if (definedUrl.isNotEmpty) return definedUrl;
          return dotenv.env['API_BASE_URL_ANDROID'] ??
              dotenv.env['API_BASE_URL'] ??
              'http://10.0.2.2:8080/api/v1';
        }
      } catch (_) {}
      if (definedUrl.isNotEmpty) return definedUrl;
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        if (definedAndroidUrl.isNotEmpty) return definedAndroidUrl;
        if (definedUrl.isNotEmpty) return definedUrl;
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    if (definedUrl.isNotEmpty) return definedUrl;

    return 'http://localhost:8080/api/v1';
  }

  // Google Client ID (Web/Server client ID) theo môi trường:
  // Thứ tự ưu tiên:
  // 1. --dart-define=GOOGLE_CLIENT_ID
  // 2. Theo host của baseUrl:
  //    - api-v2.closy.hycat.online -> GOOGLE_CLIENT_ID_V2
  //    - api.closy.hycat.online -> GOOGLE_CLIENT_ID_PROD
  //    - localhost / 10.0.2.2 -> GOOGLE_CLIENT_ID (dev)
  // 3. Fallback GOOGLE_CLIENT_ID từ .env
  static String get googleClientId {
    const defined = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (defined.isNotEmpty) return defined;

    final currentBase = baseUrl.toLowerCase();
    if (dotenv.isInitialized) {
      if (currentBase.contains('api-v2.closy.hycat.online')) {
        final v2Id = dotenv.env['GOOGLE_CLIENT_ID_V2'];
        if (v2Id != null && v2Id.isNotEmpty) return v2Id;
      } else if (currentBase.contains('api.closy.hycat.online')) {
        final prodId = dotenv.env['GOOGLE_CLIENT_ID_PROD'];
        if (prodId != null && prodId.isNotEmpty) return prodId;
      }
      final devId = dotenv.env['GOOGLE_CLIENT_ID'];
      if (devId != null && devId.isNotEmpty) return devId;
    }
    return '';
  }

  // Storage Keys
  static const String tokenKey = 'sw_auth_token';
  static const String refreshTokenKey = 'sw_refresh_token';
  static const String userProfileKey = 'sw_user_profile';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String googleAuthEndpoint = '/auth/google';

  /// URL khởi động đăng nhập Google trên **Web** qua BE (luồng redirect —
  /// guide §1). Không cần "Authorized JavaScript origins" như GIS.
  static String googleWebRedirectUrl(String returnUrl) =>
      '$baseUrl$googleAuthEndpoint?redirectUrl=${Uri.encodeComponent(returnUrl)}';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';
  static const String wardrobeEndpoint = '/me/wardrobe-items';
  static const String categoriesEndpoint = '/categories';
  static const String uploadSignatureEndpoint =
      '/wardrobe-items/upload-signature';
  static const String batchUploadEndpoint = '/wardrobe-items/batch-upload';
  static const String stylistRecommendationsEndpoint =
      '/ai/outfit-recommendations';
  static const String marketProductsEndpoint = '/market/products';
  static const String profileEndpoint = '/me';
}
