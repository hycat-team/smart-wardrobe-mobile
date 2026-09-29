import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/post_models.dart';
import 'community_feed_provider.dart';

class PostDetailState {
  final Post? post;
  final bool isLoading;
  final String? errorMessage;
  final bool isNotFound;

  const PostDetailState({
    this.post,
    this.isLoading = false,
    this.errorMessage,
    this.isNotFound = false,
  });

  PostDetailState copyWith({
    Post? post,
    bool? isLoading,
    String? errorMessage,
    bool? isNotFound,
    bool clearError = false,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isNotFound: isNotFound ?? this.isNotFound,
    );
  }
}

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final CommunityRepository _repository;
  final Ref? _ref;
  final String publicId;

  PostDetailNotifier(this._repository, this._ref, this.publicId)
      : super(const PostDetailState(isLoading: true)) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, clearError: true, isNotFound: false);

    try {
      final post = await _repository.getPostDetail(publicId);
      if (!mounted) return;
      state = state.copyWith(
        post: post,
        isLoading: false,
        clearError: true,
      );
      // Đồng bộ sang feed nếu có
      _ref?.read(communityFeedProvider.notifier).updatePost(post);
    } on DioException catch (e) {
      if (!mounted) return;
      final is404 = e.response?.statusCode == 404;
      state = state.copyWith(
        isLoading: false,
        isNotFound: is404,
        errorMessage: is404
            ? 'Bài viết không tồn tại hoặc đã bị ẩn.'
            : extractCommunityErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: extractCommunityErrorMessage(e),
      );
    }
  }

  /// Optimistic like toggle trên màn chi tiết bài viết
  Future<void> toggleLike() async {
    final current = state.post;
    if (current == null) return;

    final targetLiked = !current.isLiked;
    final updatedCount = targetLiked
        ? current.likeCount + 1
        : (current.likeCount > 0 ? current.likeCount - 1 : 0);

    final optimistic = current.copyWith(
      isLiked: targetLiked,
      likeCount: updatedCount,
    );

    state = state.copyWith(post: optimistic);
    _ref?.read(communityFeedProvider.notifier).updatePost(optimistic);

    try {
      await _repository.likePost(publicId, isLiked: targetLiked);
    } catch (e) {
      // Rollback
      state = state.copyWith(post: current);
      _ref?.read(communityFeedProvider.notifier).updatePost(current);
      rethrow;
    }
  }

  /// Cập nhật số bình luận khi thêm/xóa bình luận
  void updateCommentCount(int delta) {
    final current = state.post;
    if (current == null) return;

    final newCount = (current.commentCount + delta).clamp(0, 999999);
    final updated = current.copyWith(commentCount: newCount);
    state = state.copyWith(post: updated);
    _ref?.read(communityFeedProvider.notifier).updatePost(updated);
  }

  void updatePost(Post updated) {
    state = state.copyWith(post: updated);
    _ref?.read(communityFeedProvider.notifier).updatePost(updated);
  }
}

final postDetailProvider =
    StateNotifierProvider.family<PostDetailNotifier, PostDetailState, String>(
        (ref, publicId) {
  final repo = ref.watch(communityRepositoryProvider);
  return PostDetailNotifier(repo, ref, publicId);
});
