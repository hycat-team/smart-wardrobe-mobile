import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/community_search_repository.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/models/search_models.dart';
import 'package:smart_wardrobe/features/community/providers/community_search_provider.dart';

class SearchTestRepository extends CommunitySearchRepository {
  String? lastQuery;
  String? lastType;
  int? lastPage;
  bool shouldThrowError = false;

  List<CommunityUser> usersToReturn = [];
  int usersTotal = 0;
  bool usersHasMore = false;

  List<Post> postsToReturn = [];
  int postsTotal = 0;
  bool postsHasMore = false;

  @override
  Future<SearchResult> searchCommunity({
    required String query,
    String type = 'all',
    String? postType,
    int page = 1,
    int limit = 20,
  }) async {
    lastQuery = query;
    lastType = type;
    lastPage = page;

    if (shouldThrowError) {
      throw Exception('Search service unavailable');
    }

    return SearchResult(
      users: PaginationResult<CommunityUser>(
        items: usersToReturn,
        metadata: PaginationMetadata(
          page: page,
          limit: limit,
          totalItems: usersTotal,
          totalPages: usersHasMore ? page + 1 : page,
        ),
      ),
      posts: PaginationResult<Post>(
        items: postsToReturn,
        metadata: PaginationMetadata(
          page: page,
          limit: limit,
          totalItems: postsTotal,
          totalPages: postsHasMore ? page + 1 : page,
        ),
      ),
    );
  }
}

void main() {
  group('Community Search Tests (US6)', () {
    test('Parse SearchResult with both users and posts', () {
      final json = {
        'users': {
          'items': [
            {
              'userId': 'u10',
              'username': 'fashion_blogger',
              'firstName': 'Linh',
              'lastName': 'Tran',
            },
          ],
          'metadata': {
            'page': 1,
            'limit': 20,
            'totalItems': 1,
            'totalPages': 1,
          },
        },
        'posts': {
          'items': [
            {
              'id': 'p1',
              'publicId': 'pub-search-1',
              'postType': 'outfit',
              'status': 'published',
              'content': 'Autumn Look',
              'createdAt': '2026-09-27T00:00:00Z',
              'updatedAt': '2026-09-27T00:00:00Z',
            },
          ],
          'metadata': {
            'page': 1,
            'limit': 20,
            'totalItems': 1,
            'totalPages': 1,
          },
        },
      };

      final result = SearchResult.fromJson(json);

      expect(result.users.items.length, 1);
      expect(result.users.items.first.displayName, 'Linh Tran');
      expect(result.users.metadata.totalItems, 1);

      expect(result.posts.items.length, 1);
      expect(result.posts.items.first.publicId, 'pub-search-1');
      expect(result.posts.items.first.content, 'Autumn Look');
      expect(result.posts.metadata.totalItems, 1);
    });

    test('Execute search updates both users and posts state', () async {
      final repo = SearchTestRepository();
      repo.usersToReturn = const [
        CommunityUser(userId: 'u1', username: 'closy_star'),
      ];
      repo.usersTotal = 1;
      repo.postsToReturn = const [
        Post(
          id: 'p1',
          publicId: 'pub-1',
          postType: 'media',
          status: 'published',
          content: 'OOTD',
          sharePath: '/community/posts/pub-1',
          createdAt: '',
          updatedAt: '',
        ),
      ];
      repo.postsTotal = 1;

      final container = ProviderContainer(
        overrides: [
          communitySearchRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(communitySearchProvider.notifier);

      await notifier.executeSearch('vintage');

      expect(repo.lastQuery, 'vintage');
      expect(notifier.state.users.length, 1);
      expect(notifier.state.users.first.username, 'closy_star');
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.posts.first.publicId, 'pub-1');
      expect(notifier.state.isLoading, isFalse);
    });

    test('Independent pagination for users and posts', () async {
      final repo = SearchTestRepository();
      repo.usersToReturn = const [
        CommunityUser(userId: 'u1', username: 'user1'),
      ];
      repo.usersTotal = 2;
      repo.usersHasMore = true;

      repo.postsToReturn = const [
        Post(
          id: 'p1',
          publicId: 'pub-1',
          postType: 'outfit',
          status: 'published',
          content: 'Look 1',
          sharePath: '/community/posts/pub-1',
          createdAt: '',
          updatedAt: '',
        ),
      ];
      repo.postsTotal = 3;
      repo.postsHasMore = true;

      final container = ProviderContainer(
        overrides: [
          communitySearchRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(communitySearchProvider.notifier);
      await notifier.executeSearch('chic');

      expect(notifier.state.usersPage, 1);
      expect(notifier.state.postsPage, 1);
      expect(notifier.state.hasMoreUsers, isTrue);
      expect(notifier.state.hasMorePosts, isTrue);

      // Load more users only
      repo.usersToReturn = const [
        CommunityUser(userId: 'u2', username: 'user2'),
      ];
      repo.usersHasMore = false;

      await notifier.loadMoreUsers();

      expect(repo.lastType, 'users');
      expect(repo.lastPage, 2);
      expect(notifier.state.usersPage, 2);
      expect(notifier.state.users.length, 2);
      expect(notifier.state.postsPage, 1); // posts page unchanged!

      // Load more posts only
      repo.postsToReturn = const [
        Post(
          id: 'p2',
          publicId: 'pub-2',
          postType: 'outfit',
          status: 'published',
          content: 'Look 2',
          sharePath: '/community/posts/pub-2',
          createdAt: '',
          updatedAt: '',
        ),
      ];
      repo.postsHasMore = false;

      await notifier.loadMorePosts();

      expect(repo.lastType, 'posts');
      expect(repo.lastPage, 2);
      expect(notifier.state.postsPage, 2);
      expect(notifier.state.posts.length, 2);
      expect(notifier.state.usersPage, 2); // users page unchanged!
    });

    test('Clear search resets state to empty defaults', () async {
      final repo = SearchTestRepository();
      final container = ProviderContainer(
        overrides: [
          communitySearchRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(communitySearchProvider.notifier);
      await notifier.executeSearch('minimalist');

      expect(notifier.state.query, 'minimalist');

      notifier.clearSearch();

      expect(notifier.state.query, isEmpty);
      expect(notifier.state.users, isEmpty);
      expect(notifier.state.posts, isEmpty);
      expect(notifier.state.usersPage, 1);
      expect(notifier.state.postsPage, 1);
    });
  });
}
