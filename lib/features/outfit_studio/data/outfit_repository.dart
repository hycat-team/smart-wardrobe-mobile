import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/bulk_deletion_result.dart';
import '../../wardrobe/models/wardrobe_models.dart';
import '../models/outfit_models.dart';

/// Kết quả phân trang outfit (scroll vô hạn — US 006).
class OutfitPaginationResult {
  final List<UserOutfitModel> items;
  final int page;
  final int total;

  const OutfitPaginationResult({
    required this.items,
    required this.page,
    required this.total,
  });
}

class OutfitRepository {
  final ApiClient _apiClient;

  OutfitRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
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

  /// Gọi API AI gợi ý phối đồ dựa theo phong cách, dịp, mùa, thời tiết
  Future<RecommendedOutfitRes> getAIRecommendation(AIOutfitRecommendationReq req) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/outfit-recommendations',
        data: req.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      final data = _parseResponseData(response.data);
      if (data == null) {
        throw Exception('Không nhận được dữ liệu từ AI Stylist.');
      }
      final outfitData = _parseResponseData(data['data']) ?? data;
      return RecommendedOutfitRes.fromJson(outfitData);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tạo gợi ý phối đồ từ AI'));
    }
  }

  /// Lấy danh sách đồ trong tủ đồ cá nhân của user
  Future<List<WardrobeItemModel>> getUserWardrobeItems() async {
    try {
      final response = await _apiClient.dio.get('/me/wardrobe-items');
      final data = _parseResponseData(response.data);
      if (data != null) {
        final nested = _parseResponseData(data['data']) ?? data;
        final itemsRaw = nested['items'] ?? nested['wardrobeItems'] ?? [];
        if (itemsRaw is List) {
          return itemsRaw
              .map((item) => WardrobeItemModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải tủ đồ cá nhân'));
    }
  }

  /// Lấy danh sách tất cả outfit của user
  Future<List<UserOutfitModel>> getMyOutfits({int page = 1, int limit = 50}) async {
    final result = await getMyOutfitsPaginated(page: page, limit: limit);
    return result.items;
  }

  /// Lấy danh sách outfit kèm phân trang (scroll vô hạn — US 006).
  Future<OutfitPaginationResult> getMyOutfitsPaginated({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/me/outfits',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = _parseResponseData(response.data);
      if (data != null) {
        final nested = _parseResponseData(data['data']) ?? data;
        final itemsRaw = nested['items'] ?? [];
        if (itemsRaw is List) {
          final items = itemsRaw
              .map((item) => UserOutfitModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return OutfitPaginationResult(
            items: items,
            page: nested['page'] is int ? nested['page'] as int : page,
            total: nested['total'] is int
                ? nested['total'] as int
                : (nested['total'] is num
                    ? (nested['total'] as num).toInt()
                    : items.length),
          );
        }
      }
      return OutfitPaginationResult(items: const [], page: page, total: 0);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải danh sách outfit'));
    }
  }

  /// Lấy chi tiết outfit theo ID (kèm danh sách món đồ)
  Future<UserOutfitModel> getOutfitDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/outfits/$id');
      final data = _parseResponseData(response.data);
      final outfitData = _parseResponseData(data?['data']) ?? data ?? {};
      return UserOutfitModel.fromJson(outfitData);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải chi tiết outfit'));
    }
  }

  /// Xoá outfit
  Future<void> deleteOutfit(String id) async {
    try {
      await _apiClient.dio.delete('/outfits/$id');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể xoá outfit'));
    }
  }

  /// Xoá hàng loạt outfit (US2).
  /// BE chưa có route bulk cho outfit nên xóa tuần tự từng `DELETE /outfits/{id}`
  /// (không `Future.wait` để giữ thứ tự + quy lỗi rõ từng mục).
  /// Không abort sớm: tiếp tục các id còn lại, gom kết quả vào [BulkDeletionResult].
  Future<BulkDeletionResult> deleteOutfits(List<String> ids) async {
    final deleted = <String>[];
    final failed = <String>[];
    final messages = <String>[];
    for (final id in ids) {
      try {
        await deleteOutfit(id);
        deleted.add(id);
      } catch (e) {
        failed.add(id);
        messages.add(e.toString().replaceAll('Exception: ', ''));
      }
    }
    return BulkDeletionResult(
      deletedIds: deleted,
      failedIds: failed,
      failureMessages: messages,
    );
  }

  /// Lưu một outfit mới vào hệ thống
  Future<Map<String, dynamic>> saveOutfit(SaveOutfitReq req) async {
    try {
      final response = await _apiClient.dio.post(
        '/outfits',
        data: req.toJson(),
      );
      final data = _parseResponseData(response.data);
      return data?['data'] is Map<String, dynamic>
          ? data!['data'] as Map<String, dynamic>
          : data ?? {};
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể lưu outfit'));
    }
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
    if (e.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ backend (vui lòng kiểm tra server).';
    }
    if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
      return 'AI Stylist phản hồi quá lâu, vui lòng thử lại sau ít phút.';
    }
    return e.message ?? fallback;
  }
}
