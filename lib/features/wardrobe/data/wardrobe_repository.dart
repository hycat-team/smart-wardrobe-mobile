import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/sse_service.dart';
import '../models/wardrobe_models.dart';

class WardrobePaginationResult {
  final List<WardrobeItemModel> items;
  final int page;
  final int limit;
  final int total;

  const WardrobePaginationResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
}

class WardrobeRepository {
  final ApiClient _apiClient;
  final SSEService _sseService;

  WardrobeRepository({ApiClient? apiClient, SSEService? sseService})
      : _apiClient = apiClient ?? ApiClient(),
        _sseService = sseService ?? SSEService();

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<WardrobePaginationResult> getMyWardrobeItems({
    int page = 1,
    int limit = 20,
    String? categorySlug,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (categorySlug != null && categorySlug.isNotEmpty && categorySlug.toLowerCase() != 'all') {
        queryParams['categorySlug'] = categorySlug;
      }

      final response = await _apiClient.dio.get(
        '/me/wardrobe-items',
        queryParameters: queryParams,
      );

      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      final rawList = (data['data'] ?? data['items'] ?? data) as List<dynamic>? ?? [];

      final items = rawList
          .map((item) => WardrobeItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return WardrobePaginationResult(
        items: items,
        page: data['page'] is int ? data['page'] : page,
        limit: data['limit'] is int ? data['limit'] : limit,
        total: data['total'] is int ? data['total'] : items.length,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải tủ đồ';
      throw Exception(message);
    }
  }

  Future<WardrobeItemModel> getWardrobeItemById(String id) async {
    try {
      final response = await _apiClient.dio.get('/wardrobe-items/$id');
      final body = response.data;
      final data = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return WardrobeItemModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải chi tiết món đồ';
      throw Exception(message);
    }
  }

  Future<WardrobeItemModel> updateWardrobeItem(
    String id, {
    double? price,
    String? categoryId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (price != null) data['price'] = price;
      if (categoryId != null && categoryId.isNotEmpty) data['categoryId'] = categoryId;

      final response = await _apiClient.dio.patch(
        '/wardrobe-items/$id',
        data: data,
      );

      final body = response.data;
      final resData = _extractMap(body['data']) ?? _extractMap(body) ?? {};
      return WardrobeItemModel.fromJson(resData);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể cập nhật món đồ';
      throw Exception(message);
    }
  }

  Future<void> deleteWardrobeItem(String id) async {
    await deleteWardrobeItems([id]);
  }

  /// Xóa hàng loạt món đồ trong một lần gọi (US2).
  /// BE `DELETE /wardrobe-items/bulk` yêu cầu `ids` non-empty (min=1).
  Future<void> deleteWardrobeItems(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _apiClient.dio.delete(
        '/wardrobe-items/bulk',
        data: {
          'ids': ids,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể xóa các món đồ';
      throw Exception(message);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      final body = response.data;
      final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];

      return rawList
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải danh mục';
      throw Exception(message);
    }
  }

  Future<UploadSignatureModel> getUploadSignature() async {
    try {
      final response = await _apiClient.dio.get('/wardrobe-items/upload-signature');
      return UploadSignatureModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tạo chữ ký upload';
      throw Exception(message);
    }
  }

  Future<List<BatchUploadItemResponse>> batchUploadWardrobeItems(List<BatchUploadItemRequest> items) async {
    try {
      final response = await _apiClient.dio.post(
        '/wardrobe-items/batch-upload',
        data: {
          'items': items.map((i) => i.toJson()).toList(),
        },
      );
      final body = response.data;
      final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];
      return rawList
          .map((item) => BatchUploadItemResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Upload và phân tích đồ thất bại';
      throw Exception(message);
    }
  }

  SSESubscription subscribeTaskSSE({
    required String taskId,
    required void Function(WardrobeTaskSSEPayload payload) onEvent,
    required void Function() onDone,
    required void Function(dynamic error) onError,
  }) {
    return _sseService.subscribeTaskSSE(
      taskId: taskId,
      onEvent: (json) {
        final payload = WardrobeTaskSSEPayload.fromJson(json);
        onEvent(payload);
      },
      onDone: onDone,
      onError: onError,
    );
  }

  Future<WardrobeInsightsModel> getWardrobeInsights() async {
    try {
      final response = await _apiClient.dio.get('/me/dashboard/wardrobe-insights');
      return WardrobeInsightsModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải thống kê tủ đồ';
      throw Exception(message);
    }
  }

  Future<WardrobeCategoryDistributionResult> getCategoryDistribution() async {
    try {
      final response = await _apiClient.dio.get('/me/dashboard/wardrobe/category-distribution');
      return WardrobeCategoryDistributionResult.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải phân bổ danh mục';
      throw Exception(message);
    }
  }

  /// Lấy danh sách trang phục mẫu từ tủ đồ hệ thống (US3).
  /// Endpoint đã có sẵn trên BE + FE web đã dùng (`GET /system-catalog/wardrobe-items`).
  /// Item trả về cùng shape `WardrobeItemRes` nên parse bằng [WardrobeItemModel].
  Future<WardrobePaginationResult> getSystemCatalogItems({
    int page = 1,
    int limit = 20,
    String? categorySlug,
    String? query,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (categorySlug != null && categorySlug.isNotEmpty && categorySlug.toLowerCase() != 'all') {
        queryParams['categorySlug'] = categorySlug;
      }
      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }

      final response = await _apiClient.dio.get(
        '/system-catalog/wardrobe-items',
        queryParameters: queryParams,
      );

      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      final rawList = (data['data'] ?? data['items'] ?? data) as List<dynamic>? ?? [];

      final items = rawList
          .map((item) => WardrobeItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return WardrobePaginationResult(
        items: items,
        page: data['page'] is int ? data['page'] : page,
        limit: data['limit'] is int ? data['limit'] : limit,
        total: data['total'] is int ? data['total'] : items.length,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể tải tủ đồ hệ thống';
      throw Exception(message);
    }
  }

  /// Thêm các mẫu hệ thống đã chọn vào tủ cá nhân (US3).
  /// `POST /wardrobe-items/catalog-init {catalogItemIds}` — không tốn quota AI.
  /// Trả về danh sách món cá nhân vừa tạo.
  Future<List<WardrobeItemModel>> initClosetFromCatalog(List<String> catalogItemIds) async {
    if (catalogItemIds.isEmpty) return [];
    try {
      final response = await _apiClient.dio.post(
        '/wardrobe-items/catalog-init',
        data: {
          'catalogItemIds': catalogItemIds,
        },
      );
      final body = response.data;
      final rawList = (body['data'] ?? body) as List<dynamic>? ?? [];
      return rawList
          .map((item) => WardrobeItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Không thể thêm đồ từ tủ hệ thống';
      throw Exception(message);
    }
  }
}
