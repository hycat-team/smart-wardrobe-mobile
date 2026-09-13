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
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    const definedAndroidUrl = String.fromEnvironment('API_BASE_URL_ANDROID');
    if (dotenv.isInitialized) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          return definedAndroidUrl.isNotEmpty
              ? definedAndroidUrl
              : (dotenv.env['API_BASE_URL_ANDROID'] ??
                  'http://[IP_ADDRESS]/api/v1');
        }
      } catch (_) {}
      if (definedUrl.isNotEmpty) return definedUrl;
      return dotenv.env['API_BASE_URL'] ?? 'http://[IP_ADDRESS]/api/v1';
    }

    try {
      if (!kIsWeb && Platform.isAndroid && definedAndroidUrl.isNotEmpty) {
        return definedAndroidUrl;
      }
    } catch (_) {}
    if (definedUrl.isNotEmpty) return definedUrl;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://[IP_ADDRESS]/api/v1';
      }
    } catch (_) {}
    return 'http://[IP_ADDRESS]/api/v1';
  }

  // Storage Keys
  static const String tokenKey = 'sw_auth_token';
  static const String refreshTokenKey = 'sw_refresh_token';
  static const String userProfileKey = 'sw_user_profile';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
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
