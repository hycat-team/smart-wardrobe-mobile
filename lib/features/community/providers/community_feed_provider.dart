import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/post_models.dart';

class CommunityFeedState {
  final List<Post> items;
  final String tab; // 'explore' | 'following'
  final String sort; // 'hot' | 'latest'
  final String? postType; // null | 'outfit' | 'media'
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const CommunityFeedState({
    this.items = const [],
    this.tab = 'explore',
    this.sort = 'hot',
    this.postType,
    this.page = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  CommunityFeedState copyWith({
    List<Post>? items,
    String? tab,
    String? sort,
    String? postType,
    bool clearPostType = false,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      items: items ?? this.items,
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      postType: clearPostType ? null : (postType ?? this.postType),
      page: page ?? this.page,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CommunityFeedNotifier extends StateNotifier<CommunityFeedState> {
  final CommunityRepository _repository;
  bool _isFetchingMore = false;

  CommunityFeedNotifier(this._repository) : super(const CommunityFeedState()) {
    loadFeed();
  }

  /// Tải mới bảng tin (explore hoặc following)
  Future<void> loadFeed({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    state = state.copyWith(
      isLoading: !isRefresh,
      clearError: true,
    );

    try {
      final result = await _repository.getCommunityPosts(
        type: state.tab,
        sort: state.sort,
        postType: state.postType,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      state = state.copyWith(
        items: result.items,
        page: 1,
        total: result.metadata.totalItems,
        hasMore: result.metadata.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: extractCommunityErrorMessage(e),
      );
    }
  }

  /// Cuộn vô hạn tải thêm (single-flight + chống trùng lặp theo publicId)
  Future<void> loadMore() async {
    if (_isFetchingMore || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    _isFetchingMore = true;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final result = await _repository.getCommunityPosts(
        type: state.tab,
        sort: state.sort,
        postType: state.postType,
        page: nextPage,
        limit: 20,
      );

      final existingIds = state.items.map((p) => p.publicId).toSet();
      final freshItems = result.items.where((p) => !existingIds.contains(p.publicId)).toList();

      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...freshItems],
        page: nextPage,
        total: result.metadata.totalItems,
        hasMore: result.metadata.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMore: false);
    } finally {
      _isFetchingMore = false;
    }
  }

  /// Chuyển tab Khám phá / Đang theo dõi
  void changeTab(String newTab) {
    if (state.tab == newTab) return;
    state = state.copyWith(tab: newTab, page: 1, hasMore: true);
    loadFeed();
  }

  /// Chuyển sắp xếp Nổi bật (hot) / Mới nhất (latest)
  void changeSort(String newSort) {
    if (state.sort == newSort) return;
    state = state.copyWith(sort: newSort, page: 1, hasMore: true);
    loadFeed();
  }

  /// Lọc theo loại bài viết (outfit / media / all)
  void changePostType(String? newType) {
    if (state.postType == newType) return;
    state = state.copyWith(
      postType: newType,
      clearPostType: newType == null,
      page: 1,
      hasMore: true,
    );
    loadFeed();
  }

  /// Cập nhật 1 bài viết trong danh sách (khi like, edit, hoặc sync từ detail)
  void updatePost(Post updated) {
    final list = [...state.items];
    final idx = list.indexWhere((p) => p.publicId == updated.publicId);
    if (idx != -1) {
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  /// Xóa 1 bài viết khỏi danh sách
  void removePost(String publicId) {
    final list = state.items.where((p) => p.publicId != publicId).toList();
    state = state.copyWith(
      items: list,
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }

  /// Optimistic Like / Unlike cho bài viết trên Feed (US3)
  Future<void> toggleLike(String publicId) async {
    final idx = state.items.indexWhere((p) => p.publicId == publicId);
    if (idx == -1) return;

    final original = state.items[idx];
    final targetLiked = !original.isLiked;
    final updatedCount = targetLiked ? original.likeCount + 1 : (original.likeCount > 0 ? original.likeCount - 1 : 0);

    final optimisticPost = original.copyWith(
      isLiked: targetLiked,
      likeCount: updatedCount,
    );

    // Áp dụng ngay trên UI
    updatePost(optimisticPost);

    try {
      await _repository.likePost(publicId, isLiked: targetLiked);
    } catch (e) {
      // Rollback nếu thất bại
      updatePost(original);
      rethrow;
    }
  }
}

final communityFeedProvider = StateNotifierProvider<CommunityFeedNotifier, CommunityFeedState>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommunityFeedNotifier(repo);
});
