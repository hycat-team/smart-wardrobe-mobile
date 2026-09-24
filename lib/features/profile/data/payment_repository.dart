import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/user_profile_models.dart';

/// Single source of truth cho mọi API thanh toán / ví / gói hội viên (PayOS).
///
/// [ProfileRepository] giữ nguyên method signature và delegate sang đây,
/// UI mới dùng trực tiếp class này để dựng [PendingPayment].
class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  // 1. Get user active subscription
  Future<UserSubscriptionModel> getMySubscription() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/me');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return UserSubscriptionModel.fromJson(data);
    } on DioException catch (_) {
      return const UserSubscriptionModel();
    }
  }

  // 2. Get user daily AI quota
  Future<DailyQuotaModel> getDailyQuota() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/me/daily-quota');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return DailyQuotaModel.fromJson(data);
    } on DioException catch (_) {
      return const DailyQuotaModel();
    }
  }

  // 3. Get all subscription plans
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/plans');
      final body = response.data;
      final data = body['data'];
      if (data is List) {
        return data.map((item) {
          final map = _extractMap(item) ?? {};
          return SubscriptionPlanModel.fromJson(map);
        }).toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  // 4. Direct Purchase / Wallet TopUp / Purchase-with-wallet: REMOVED.
  // Luồng thanh toán chuyển lên website (009-web-payment-redirect) —
  // mobile không tạo yêu cầu thanh toán và không mở trang thanh toán.
  // Giữ lại các API đọc (plans / subscription / quota / wallet) bên dưới.

  // 5. Wallet - Get user balance
  Future<WalletModel> getWallet() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/me/wallet');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return WalletModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải số dư ví'));
    }
  }

  // 6. Wallet - Get statements
  Future<List<WalletStatementModel>> getWalletStatements({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/subscriptions/me/wallet/statements',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final body = response.data;
      final data = body['data'];
      List items = [];
      if (data is Map && data['items'] is List) {
        items = data['items'];
      } else if (data is List) {
        items = data;
      } else if (body['items'] is List) {
        items = body['items'];
      }
      return items.map((item) => WalletStatementModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } on DioException catch (_) {
      return [];
    }
  }
}

