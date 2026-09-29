import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_error.dart';
import '../data/user_social_repository.dart';
import '../models/post_models.dart';
import '../models/profile_models.dart';

class PublicProfileState {
  final PublicProfile? profile;
  final List<Post> posts;
  final int postsPage;
  final int totalPosts;
  final bool hasMorePosts;
  final bool isLoading;
  final bool isLoadingMorePosts;
  final String? errorMessage;

  const PublicProfileState({
    this.profile,
    this.posts = const [],
    this.postsPage = 1,
    this.totalPosts = 0,
    this.hasMorePosts = false,
    this.isLoading = false,
    this.isLoadingMorePosts = false,
    this.errorMessage,
  });

  PublicProfileState copyWith({
    PublicProfile? profile,
    List<Post>? posts,
    int? postsPage,
    int? totalPosts,
    bool? hasMorePosts,
    bool? isLoading,
    bool? isLoadingMorePosts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublicProfileState(
      profile: profile ?? this.profile,
      posts: posts ?? this.posts,
      postsPage: postsPage ?? this.postsPage,
      totalPosts: totalPosts ?? this.totalPosts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PublicProfileNotifier extends StateNotifier<PublicProfileState> {
  final UserSocialRepository _repository;
  final String username;
  bool _isFetchingMore = false;

  PublicProfileNotifier(this._repository, this.username)
      : super(const PublicProfileState(isLoading: true)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profileFuture = _repository.getPublicProfile(username);
      final postsFuture = _repository.getUserPosts(username, page: 1, limit: 20);

      final results = await Future.wait([profileFuture, postsFuture]);
      final profile = results[0] as PublicProfile;
      final postsRes = results[1] as dynamic;

      if (!mounted) return;
      state = state.copyWith(
        profile: profile,
        posts: postsRes.items as List<Post>,
        postsPage: 1,
        totalPosts: postsRes.metadata.totalItems as int,
        hasMorePosts: postsRes.metadata.hasMore as bool,
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

  Future<void> loadMorePosts() async {
    if (_isFetchingMore || state.isLoading || state.isLoadingMorePosts || !state.hasMorePosts) {
      return;
    }

    _isFetchingMore = true;
    state = state.copyWith(isLoadingMorePosts: true);

    try {
      final nextPage = state.postsPage + 1;
      final res = await _repository.getUserPosts(username, page: nextPage, limit: 20);

      final existingIds = state.posts.map((p) => p.publicId).toSet();
      final fresh = res.items.where((p) => !existingIds.contains(p.publicId)).toList();

      if (!mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...fresh],
        postsPage: nextPage,
        totalPosts: res.metadata.totalItems,
        hasMorePosts: res.metadata.hasMore,
        isLoadingMorePosts: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMorePosts: false);
    } finally {
      _isFetchingMore = false;
    }
  }

  /// Optimistic Follow / Unfollow
  Future<void> toggleFollow() async {
    final current = state.profile;
    if (current == null || current.isMe) return;

    final targetFollow = !current.isFollowing;
    final updatedFollowerCount = targetFollow
        ? current.stats.followerCount + 1
        : (current.stats.followerCount > 0 ? current.stats.followerCount - 1 : 0);

    final optimistic = current.copyWith(
      isFollowing: targetFollow,
      stats: current.stats.copyWith(followerCount: updatedFollowerCount),
    );

    state = state.copyWith(profile: optimistic);

    try {
      await _repository.followUser(username, isFollowing: targetFollow);
    } catch (e) {
      // Rollback
      if (mounted) {
        state = state.copyWith(profile: current);
      }
      rethrow;
    }
  }
}

final publicProfileProvider = StateNotifierProvider.family<
    PublicProfileNotifier, PublicProfileState, String>((ref, username) {
  final repo = ref.watch(userSocialRepositoryProvider);
  return PublicProfileNotifier(repo, username);
});

class UserFollowsState {
  final List<FollowUser> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String type; // 'following' | 'followers'
  final String query;
  final String? errorMessage;

  const UserFollowsState({
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.type = 'following',
    this.query = '',
    this.errorMessage,
  });

  UserFollowsState copyWith({
    List<FollowUser>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? type,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserFollowsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      type: type ?? this.type,
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserFollowsNotifier extends StateNotifier<UserFollowsState> {
  final UserSocialRepository _repository;
  final String username;
  bool _isFetchingMore = false;

  UserFollowsNotifier(this._repository, this.username, {String initialType = 'following'})
      : super(UserFollowsState(type: initialType, isLoading: true)) {
    loadFollows();
  }

  Future<void> loadFollows() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getUserFollows(
        username,
        type: state.type,
        q: state.query.isNotEmpty ? state.query : null,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      state = state.copyWith(
        items: res.items,
        page: 1,
        hasMore: res.metadata.hasMore,
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

  Future<void> loadMore() async {
    if (_isFetchingMore || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    _isFetchingMore = true;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final res = await _repository.getUserFollows(
        username,
        type: state.type,
        q: state.query.isNotEmpty ? state.query : null,
        page: nextPage,
        limit: 20,
      );

      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...res.items],
        page: nextPage,
        hasMore: res.metadata.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMore: false);
    } finally {
      _isFetchingMore = false;
    }
  }

  void changeType(String newType) {
    if (state.type == newType) return;
    state = state.copyWith(type: newType, page: 1, hasMore: true);
    loadFollows();
  }

  void search(String query) {
    state = state.copyWith(query: query.trim(), page: 1, hasMore: true);
    loadFollows();
  }
}

final userFollowsProvider = StateNotifierProvider.family<
    UserFollowsNotifier, UserFollowsState, (String, String)>((ref, args) {
  final repo = ref.watch(userSocialRepositoryProvider);
  return UserFollowsNotifier(repo, args.$1, initialType: args.$2);
});
