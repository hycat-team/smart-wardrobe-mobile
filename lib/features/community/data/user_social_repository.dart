import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/post_models.dart';
import '../models/profile_models.dart';
import '../models/search_models.dart';

final userSocialRepositoryProvider = Provider<UserSocialRepository>((ref) {
  return UserSocialRepository();
});

class UserSocialRepository {
  final ApiClient _apiClient;

  UserSocialRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Theo dõi / Bỏ theo dõi người dùng
  Future<void> followUser(String username, {required bool isFollowing}) async {
    await _dio.put(
      '/users/$username/follow',
      data: {'isFollowing': isFollowing},
    );
  }

  /// Lấy thông tin hồ sơ công khai của người dùng (kèm stats, isFollowing, isMe)
  Future<PublicProfile> getPublicProfile(String username) async {
    final response = await _dio.get('/users/$username');
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return PublicProfile.fromJson(data);
  }

  /// Lấy danh sách bài viết của người dùng
  Future<PaginationResult<Post>> getUserPosts(
    String username, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/$username/posts',
      queryParameters: {'page': page, 'limit': limit},
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return PaginationResult<Post>.fromJson(
      data,
      (item) => Post.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// Lấy danh sách đang theo dõi hoặc người theo dõi
  Future<PaginationResult<FollowUser>> getUserFollows(
    String username, {
    String? type, // 'following' | 'followers'
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null && type.isNotEmpty && type != 'all') {
      query['type'] = type;
    }
    if (q != null && q.trim().isNotEmpty) {
      query['q'] = q.trim();
    }

    final response = await _dio.get(
      '/users/$username/follows',
      queryParameters: query,
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return PaginationResult<FollowUser>.fromJson(
      data,
      (item) => FollowUser.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }
}
