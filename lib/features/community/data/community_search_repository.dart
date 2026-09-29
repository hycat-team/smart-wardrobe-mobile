import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/search_models.dart';

final communitySearchRepositoryProvider = Provider<CommunitySearchRepository>((ref) {
  return CommunitySearchRepository();
});

class CommunitySearchRepository {
  final ApiClient _apiClient;

  CommunitySearchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Tìm kiếm bài viết và người dùng trong cộng đồng
  Future<SearchResult> searchCommunity({
    required String query,
    String type = 'all', // 'all' | 'users' | 'posts'
    String? postType,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'q': query.trim(),
      'type': type,
      'page': page,
      'limit': limit,
    };
    if (postType != null && postType.isNotEmpty) {
      params['postType'] = postType;
    }

    final response = await _dio.get(
      '/search',
      queryParameters: params,
    );

    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return SearchResult.fromJson(data);
  }
}
