import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'Smart Wardrobe';

  // Cloudinary Cloud Name with fallback
  static String get cloudinaryCloudName {
    if (dotenv.isInitialized) {
      return dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dzvwkngxu';
    }
    return 'dzvwkngxu';
  }

  // Base API URL with Android emulator support & .env loading
  static String get baseUrl {
    if (dotenv.isInitialized) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:8080/api/v1';
        }
      } catch (_) {}
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
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
  static const String uploadSignatureEndpoint = '/wardrobe-items/upload-signature';
  static const String batchUploadEndpoint = '/wardrobe-items/batch-upload';
  static const String stylistRecommendationsEndpoint = '/ai/outfit-recommendations';
  static const String marketProductsEndpoint = '/market/products';
  static const String profileEndpoint = '/me';
}
