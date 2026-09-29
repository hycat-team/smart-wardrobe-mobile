import 'community_user.dart';
import 'post_models.dart';

class PaginationMetadata {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const PaginationMetadata({
    this.page = 1,
    this.limit = 20,
    this.totalItems = 0,
    this.totalPages = 0,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    return PaginationMetadata(
      page: json['page'] is int ? json['page'] as int : int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: json['limit'] is int ? json['limit'] as int : int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      totalItems: json['totalItems'] is int ? json['totalItems'] as int : int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] as int : int.tryParse(json['totalPages']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalItems': totalItems,
      'totalPages': totalPages,
    };
  }

  bool get hasMore => page < totalPages;
}

class PaginationResult<T> {
  final List<T> items;
  final PaginationMetadata metadata;

  const PaginationResult({
    required this.items,
    required this.metadata,
  });

  factory PaginationResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) itemParser,
  ) {
    final rawItems = json['items'];
    final itemsList = <T>[];
    if (rawMediaOrItems(rawItems)) {
      for (final item in rawItems as List) {
        try {
          itemsList.add(itemParser(item));
        } catch (_) {}
      }
    }

    final rawMeta = json['metadata'];
    final meta = rawMeta is Map<String, dynamic>
        ? PaginationMetadata.fromJson(rawMeta)
        : const PaginationMetadata();

    return PaginationResult<T>(
      items: itemsList,
      metadata: meta,
    );
  }

  static bool rawMediaOrItems(dynamic raw) => raw is List;
}

class SearchResult {
  final PaginationResult<CommunityUser> users;
  final PaginationResult<Post> posts;

  const SearchResult({
    required this.users,
    required this.posts,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    PaginationResult<CommunityUser> usersResult;
    final rawUsers = json['users'];
    if (rawUsers is Map<String, dynamic>) {
      usersResult = PaginationResult.fromJson(
        rawUsers,
        (item) => CommunityUser.fromJson(item as Map<String, dynamic>),
      );
    } else if (rawUsers is List) {
      usersResult = PaginationResult<CommunityUser>(
        items: rawUsers
            .whereType<Map<String, dynamic>>()
            .map(CommunityUser.fromJson)
            .toList(),
        metadata: PaginationMetadata(
          page: 1,
          limit: rawUsers.length,
          totalItems: rawUsers.length,
          totalPages: 1,
        ),
      );
    } else {
      usersResult = const PaginationResult(
        items: [],
        metadata: PaginationMetadata(),
      );
    }

    PaginationResult<Post> postsResult;
    final rawPosts = json['posts'];
    if (rawPosts is Map<String, dynamic>) {
      postsResult = PaginationResult.fromJson(
        rawPosts,
        (item) => Post.fromJson(item as Map<String, dynamic>),
      );
    } else if (rawPosts is List) {
      postsResult = PaginationResult<Post>(
        items: rawPosts
            .whereType<Map<String, dynamic>>()
            .map(Post.fromJson)
            .toList(),
        metadata: PaginationMetadata(
          page: 1,
          limit: rawPosts.length,
          totalItems: rawPosts.length,
          totalPages: 1,
        ),
      );
    } else {
      postsResult = const PaginationResult(
        items: [],
        metadata: PaginationMetadata(),
      );
    }

    return SearchResult(
      users: usersResult,
      posts: postsResult,
    );
  }
}
