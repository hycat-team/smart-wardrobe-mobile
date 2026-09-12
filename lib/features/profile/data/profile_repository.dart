import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/auth_models.dart';
import '../models/body_profile_models.dart';
import '../models/user_profile_models.dart';
import 'payment_repository.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  final Dio _cloudinaryDio;
  PaymentRepository? _payments;

  ProfileRepository({ApiClient? apiClient, Dio? cloudinaryDio})
      : _apiClient = apiClient ?? ApiClient(),
        _cloudinaryDio = cloudinaryDio ?? Dio();

  /// Payment APIs — single implementation lives in [PaymentRepository].
  PaymentRepository get payments =>
      _payments ??= PaymentRepository(apiClient: _apiClient);

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  // 1. Get current user profile
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/me');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải thông tin người dùng';
      throw Exception(message);
    }
  }

  // 2. Update user basic profile (Name, DOB, Gender, Address)
  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiClient.dio.put(
        '/me',
        data: request.toJson(),
      );
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật thông tin cá nhân';
      throw Exception(message);
    }
  }

  // 3. Change password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _apiClient.dio.put(
        '/me/change-password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu cũ.';
      if (data is Map) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();
        } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final firstErr = data['errors'][0];
          if (firstErr is Map && firstErr['message'] != null) {
            message = firstErr['message'].toString();
          }
        }
      }
      throw Exception(message);
    }
  }

  // 4. Get Avatar Signature for Cloudinary upload
  Future<AvatarSignatureModel> getAvatarSignature() async {
    try {
      final response = await _apiClient.dio.get('/me/avatar-signature');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return AvatarSignatureModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể lấy chữ ký tải ảnh';
      throw Exception(message);
    }
  }

  // 5. Upload Avatar File directly to Cloudinary
  Future<Map<String, String>> uploadAvatarFile(XFile file, AvatarSignatureModel signature) async {
    try {
      final cloudName = AppConstants.cloudinaryCloudName;
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
        'api_key': signature.apiKey,
        'timestamp': signature.timestamp.toString(),
        'signature': signature.signature,
        'folder': signature.folder,
        if (signature.publicId != null && signature.publicId!.isNotEmpty) ...{
          'public_id': signature.publicId,
          'overwrite': 'true',
        },
      });

      final response = await _cloudinaryDio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'avatarUrl': data['secure_url'] as String,
          'publicId': data['public_id'] as String,
        };
      } else {
        throw Exception('Lỗi khi tải ảnh lên máy chủ ảnh.');
      }
    } catch (e) {
      throw Exception('Không thể tải ảnh lên Cloudinary: ${e.toString()}');
    }
  }

  // 6. Update user avatar in backend
  Future<void> updateAvatar(String avatarUrl, String publicId) async {
    try {
      await _apiClient.dio.put(
        '/me/avatar',
        data: {
          'avatarUrl': avatarUrl,
          'avatarPublicId': publicId,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật ảnh đại diện';
      throw Exception(message);
    }
  }

  // 7. Get user active subscription (delegated to PaymentRepository)
  Future<UserSubscriptionModel> getMySubscription() =>
      payments.getMySubscription();

  // 8. Get user daily AI quota (delegated to PaymentRepository)
  Future<DailyQuotaModel> getDailyQuota() => payments.getDailyQuota();

  // 9. Get all subscription plans (delegated to PaymentRepository)
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() =>
      payments.getSubscriptionPlans();

  // 10. Create Direct Purchase Link via PayOS (delegated to PaymentRepository)
  Future<PaymentLinkModel> createDirectPurchase({
    required String planSlug,
    String? returnUrl,
    String? cancelUrl,
  }) =>
      payments.createDirectPurchase(
        planSlug: planSlug,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );

// 11. Body Profile
  Future<BodyProfileModel> getBodyProfile() async {
    try {
      final response = await _apiClient.dio.get('/me');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      final bodyProfileJson = _extractMap(data['bodyProfile']);

      if (bodyProfileJson != null) {
        return BodyProfileModel.fromJson(bodyProfileJson);
      }
      return const BodyProfileModel();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải hồ sơ vóc dáng';
      throw Exception(message);
    }
  }

  // 12. Update Body Profile
  Future<BodyProfileModel> updateBodyProfile(BodyProfileModel profile) async {
    try {
      final response = await _apiClient.dio.put(
        '/me/body-profile',
        data: profile.toJson(),
      );

      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return BodyProfileModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật hồ sơ vóc dáng';
      throw Exception(message);
    }
  }

  // 10d. Wallet - Get user balance (delegated to PaymentRepository)
  Future<WalletModel> getWallet() => payments.getWallet();

  // 10e. Wallet - Get statements (delegated to PaymentRepository)
  Future<List<WalletStatementModel>> getWalletStatements({int page = 1, int pageSize = 20}) =>
      payments.getWalletStatements(page: page, pageSize: pageSize);

  // 10f. Wallet - Create topup link (delegated to PaymentRepository)
  Future<PaymentLinkModel> createWalletTopUp(double amount, {String? returnUrl, String? cancelUrl}) =>
      payments.createWalletTopUp(amount, returnUrl: returnUrl, cancelUrl: cancelUrl);

  // 10g. Subscription - Purchase plan with wallet (delegated to PaymentRepository)
  Future<void> purchasePlanWithWallet(String planSlug) =>
      payments.purchasePlanWithWallet(planSlug);

}
