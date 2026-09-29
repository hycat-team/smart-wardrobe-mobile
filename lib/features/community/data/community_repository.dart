import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../wardrobe/models/wardrobe_models.dart';
import '../models/community_user.dart';
import '../models/comment_models.dart';
import '../models/post_models.dart';
import '../models/search_models.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Dio get _dio => _apiClient.dio;

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Lấy danh sách bài viết cộng đồng (explore / following; sort: hot / latest)
  Future<PaginationResult<Post>> getCommunityPosts({
    String type = 'explore',
    String sort = 'latest',
    String? postType,
    String? username,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'type': type,
      'sort': sort,
      'page': page,
      'limit': limit,
    };
    if (postType != null && postType.isNotEmpty) {
      query['postType'] = postType;
    }
    if (username != null && username.isNotEmpty) {
      query['username'] = username;
    }

    final response = await _dio.get(
      '/posts',
      queryParameters: query,
    );

    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};

    return PaginationResult<Post>.fromJson(
      data,
      (item) => Post.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// Xem chi tiết một bài viết theo publicId
  Future<Post> getPostDetail(String publicId) async {
    final response = await _dio.get('/posts/$publicId');
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return Post.fromJson(data);
  }

  /// Lấy chữ ký tải lên Cloudinary cho bài viết cộng đồng (ảnh hoặc video)
  Future<UploadSignatureModel> getUploadSignaturePost({
    String resourceType = 'image',
  }) async {
    final response = await _dio.get(
      '/posts/upload-signature',
      queryParameters: {'resourceType': resourceType},
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return UploadSignatureModel.fromJson({
      ...data,
      'resourceType': resourceType,
    });
  }

  /// Tạo bài viết mới (outfit hoặc media)
  Future<Post> createPost(CreatePostReq req) async {
    final response = await _dio.post(
      '/posts',
      data: req.toJson(),
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return Post.fromJson(data);
  }

  /// Cập nhật bài viết của mình
  Future<Post> updatePost(String publicId, UpdatePostReq req) async {
    final response = await _dio.put(
      '/posts/$publicId',
      data: req.toJson(),
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return Post.fromJson(data);
  }

  /// Xóa bài viết
  Future<void> deletePost(String publicId) async {
    await _dio.delete('/posts/$publicId');
  }

  /// Thích / Bỏ thích bài viết
  Future<void> likePost(String publicId, {required bool isLiked}) async {
    await _dio.put(
      '/posts/$publicId/like',
      data: {'isLiked': isLiked},
    );
  }

  /// Danh sách người dùng thích bài viết có phân trang
  Future<PaginationResult<CommunityUser>> getPostLikes(
    String publicId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/posts/$publicId/likes',
      queryParameters: {'page': page, 'limit': limit},
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return PaginationResult<CommunityUser>.fromJson(
      data,
      (item) => CommunityUser.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// Lấy danh sách bình luận gốc của bài viết (mới -> cũ)
  Future<List<Comment>> getPostComments(String publicId) async {
    final response = await _dio.get('/posts/$publicId/comments');
    final resData = _extractMap(response.data);
    final rawList = resData?['data'] is List ? resData!['data'] as List : <dynamic>[];
    return rawList
        .whereType<Map>()
        .map((item) => Comment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Lấy danh sách phản hồi (replies) của một bình luận gốc (cũ -> mới)
  Future<List<Comment>> getCommentReplies(String publicId, String commentId) async {
    final response = await _dio.get('/posts/$publicId/comments/$commentId/replies');
    final resData = _extractMap(response.data);
    final rawList = resData?['data'] is List ? resData!['data'] as List : <dynamic>[];
    return rawList
        .whereType<Map>()
        .map((item) => Comment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Gửi bình luận mới hoặc phản hồi
  Future<Comment> addComment(
    String publicId, {
    required String content,
    String? parentCommentId,
  }) async {
    final payload = <String, dynamic>{
      'content': content.trim(),
      if (parentCommentId != null && parentCommentId.isNotEmpty)
        'parentCommentId': parentCommentId,
    };
    final response = await _dio.post(
      '/posts/$publicId/comments',
      data: payload,
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return Comment.fromJson(data);
  }

  /// Chỉnh sửa bình luận của mình
  Future<Comment> updateComment(
    String publicId,
    String commentId, {
    required String content,
  }) async {
    final response = await _dio.put(
      '/posts/$publicId/comments/$commentId',
      data: {'content': content.trim()},
    );
    final resData = _extractMap(response.data);
    final data = _extractMap(resData?['data']) ?? resData ?? <String, dynamic>{};
    return Comment.fromJson(data);
  }

  /// Xóa bình luận
  Future<void> deleteComment(String publicId, String commentId) async {
    await _dio.delete('/posts/$publicId/comments/$commentId');
  }
}
