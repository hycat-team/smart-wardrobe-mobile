import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_error.dart';
import '../data/community_search_repository.dart';
import '../models/community_user.dart';
import '../models/post_models.dart';

class CommunitySearchState {
  final String query;
  final String searchType; // 'all' | 'users' | 'posts'
  final String? postTypeFilter; // null | 'outfit' | 'media'
  final List<CommunityUser> users;
  final int usersPage;
  final int totalUsers;
  final bool hasMoreUsers;
  final List<Post> posts;
  final int postsPage;
  final int totalPosts;
  final bool hasMorePosts;
  final bool isLoading;
  final bool isLoadingMoreUsers;
  final bool isLoadingMorePosts;
  final String? errorMessage;

  const CommunitySearchState({
    this.query = '',
    this.searchType = 'all',
    this.postTypeFilter,
    this.users = const [],
    this.usersPage = 1,
    this.totalUsers = 0,
    this.hasMoreUsers = false,
    this.posts = const [],
    this.postsPage = 1,
    this.totalPosts = 0,
    this.hasMorePosts = false,
    this.isLoading = false,
    this.isLoadingMoreUsers = false,
    this.isLoadingMorePosts = false,
    this.errorMessage,
  });

  CommunitySearchState copyWith({
    String? query,
    String? searchType,
    String? postTypeFilter,
    bool clearPostTypeFilter = false,
    List<CommunityUser>? users,
    int? usersPage,
    int? totalUsers,
    bool? hasMoreUsers,
    List<Post>? posts,
    int? postsPage,
    int? totalPosts,
    bool? hasMorePosts,
    bool? isLoading,
    bool? isLoadingMoreUsers,
    bool? isLoadingMorePosts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunitySearchState(
      query: query ?? this.query,
      searchType: searchType ?? this.searchType,
      postTypeFilter: clearPostTypeFilter ? null : (postTypeFilter ?? this.postTypeFilter),
      users: users ?? this.users,
      usersPage: usersPage ?? this.usersPage,
      totalUsers: totalUsers ?? this.totalUsers,
      hasMoreUsers: hasMoreUsers ?? this.hasMoreUsers,
      posts: posts ?? this.posts,
      postsPage: postsPage ?? this.postsPage,
      totalPosts: totalPosts ?? this.totalPosts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMoreUsers: isLoadingMoreUsers ?? this.isLoadingMoreUsers,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CommunitySearchNotifier extends StateNotifier<CommunitySearchState> {
  final CommunitySearchRepository _repository;
  Timer? _debounceTimer;
  bool _isFetchingUsers = false;
  bool _isFetchingPosts = false;

  CommunitySearchNotifier(this._repository) : super(const CommunitySearchState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Gọi khi gõ phím với debounce 400ms
  void onQueryChanged(String newQuery) {
    final trimmed = newQuery.trim();
    if (trimmed == state.query) return;

    _debounceTimer?.cancel();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: '',
        users: const [],
        posts: const [],
        usersPage: 1,
        postsPage: 1,
        totalUsers: 0,
        totalPosts: 0,
        hasMoreUsers: false,
        hasMorePosts: false,
        isLoading: false,
        clearError: true,
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      executeSearch(trimmed);
    });
  }

  /// Tìm kiếm ngay lập tức (khi submit hoặc đổi tab filter)
  Future<void> executeSearch(
    String query, {
    String? searchType,
    String? postTypeFilter,
  }) async {
    _debounceTimer?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(
        query: '',
        users: const [],
        posts: const [],
        usersPage: 1,
        postsPage: 1,
        totalUsers: 0,
        totalPosts: 0,
        hasMoreUsers: false,
        hasMorePosts: false,
        isLoading: false,
        clearError: true,
      );
      return;
    }

    final targetType = searchType ?? state.searchType;
    final targetPostType = postTypeFilter ?? state.postTypeFilter;

    state = state.copyWith(
      query: q,
      searchType: targetType,
      postTypeFilter: targetPostType,
      isLoading: true,
      clearError: true,
    );

    try {
      final res = await _repository.searchCommunity(
        query: q,
        type: targetType,
        postType: targetPostType,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;

      state = state.copyWith(
        users: res.users.items,
        usersPage: 1,
        totalUsers: res.users.metadata.totalItems,
        hasMoreUsers: res.users.metadata.hasMore,
        posts: res.posts.items,
        postsPage: 1,
        totalPosts: res.posts.metadata.totalItems,
        hasMorePosts: res.posts.metadata.hasMore,
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

  void changeSearchType(String newType) {
    if (state.searchType == newType) return;
    state = state.copyWith(searchType: newType);
    if (state.query.isNotEmpty) {
      executeSearch(state.query, searchType: newType);
    }
  }

  void changePostTypeFilter(String? newPostType) {
    if (state.postTypeFilter == newPostType) return;
    if (newPostType == null) {
      state = state.copyWith(clearPostTypeFilter: true);
    } else {
      state = state.copyWith(postTypeFilter: newPostType);
    }
    if (state.query.isNotEmpty) {
      executeSearch(state.query, postTypeFilter: newPostType);
    }
  }

  Future<void> loadMoreUsers() async {
    if (_isFetchingUsers || state.isLoading || state.isLoadingMoreUsers || !state.hasMoreUsers) {
      return;
    }

    _isFetchingUsers = true;
    state = state.copyWith(isLoadingMoreUsers: true);

    try {
      final nextPage = state.usersPage + 1;
      final res = await _repository.searchCommunity(
        query: state.query,
        type: 'users',
        page: nextPage,
        limit: 20,
      );

      final existingIds = state.users.map((u) => u.userId).toSet();
      final freshUsers = res.users.items.where((u) => !existingIds.contains(u.userId)).toList();

      if (!mounted) return;
      state = state.copyWith(
        users: [...state.users, ...freshUsers],
        usersPage: nextPage,
        totalUsers: res.users.metadata.totalItems,
        hasMoreUsers: res.users.metadata.hasMore,
        isLoadingMoreUsers: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMoreUsers: false);
    } finally {
      _isFetchingUsers = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (_isFetchingPosts || state.isLoading || state.isLoadingMorePosts || !state.hasMorePosts) {
      return;
    }

    _isFetchingPosts = true;
    state = state.copyWith(isLoadingMorePosts: true);

    try {
      final nextPage = state.postsPage + 1;
      final res = await _repository.searchCommunity(
        query: state.query,
        type: 'posts',
        postType: state.postTypeFilter,
        page: nextPage,
        limit: 20,
      );

      final existingIds = state.posts.map((p) => p.publicId).toSet();
      final freshPosts = res.posts.items.where((p) => !existingIds.contains(p.publicId)).toList();

      if (!mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...freshPosts],
        postsPage: nextPage,
        totalPosts: res.posts.metadata.totalItems,
        hasMorePosts: res.posts.metadata.hasMore,
        isLoadingMorePosts: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMorePosts: false);
    } finally {
      _isFetchingPosts = false;
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = const CommunitySearchState();
  }
}

final communitySearchProvider =
    StateNotifierProvider<CommunitySearchNotifier, CommunitySearchState>((ref) {
  final repo = ref.watch(communitySearchRepositoryProvider);
  return CommunitySearchNotifier(repo);
});
