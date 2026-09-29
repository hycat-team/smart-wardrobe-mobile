import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/models/search_models.dart';
import 'package:smart_wardrobe/features/community/providers/community_feed_provider.dart';
import 'package:smart_wardrobe/features/community/providers/post_detail_provider.dart';

class LikeTestCommunityRepository extends CommunityRepository {
  bool shouldThrowError = false;
  String? lastLikedPublicId;
  bool? lastIsLiked;
  Post? postDetail;

  @override
  Future<PaginationResult<Post>> getCommunityPosts({
    String type = 'explore',
    String sort = 'latest',
    String? postType,
    String? username,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginationResult<Post>(
      items: postDetail != null ? [postDetail!] : [],
      metadata: const PaginationMetadata(page: 1, limit: 20, totalItems: 1, totalPages: 1),
    );
  }

  @override
  Future<Post> getPostDetail(String publicId) async {
    if (postDetail != null) return postDetail!;
    return Post(
      id: '1',
      publicId: publicId,
      postType: 'outfit',
      status: 'published',
      content: 'Test post',
      sharePath: '/community/posts/$publicId',
      createdAt: '',
      updatedAt: '',
    );
  }

  @override
  Future<void> likePost(String publicId, {required bool isLiked}) async {
    lastLikedPublicId = publicId;
    lastIsLiked = isLiked;
    if (shouldThrowError) {
      throw Exception('Network error');
    }
  }

  @override
  Future<PaginationResult<CommunityUser>> getPostLikes(
    String publicId, {
    int page = 1,
    int limit = 20,
  }) async {
    return PaginationResult<CommunityUser>(
      items: const [
        CommunityUser(userId: 'u1', username: 'user1'),
        CommunityUser(userId: 'u2', username: 'user2'),
      ],
      metadata: const PaginationMetadata(page: 1, limit: 20, totalItems: 2, totalPages: 1),
    );
  }
}

void main() {
  group('Community Like Tests (US3)', () {
    test('Optimistic like toggles state immediately and syncs with server', () async {
      final repo = LikeTestCommunityRepository();
      const initialPost = Post(
        id: '1',
        publicId: 'pub-test-1',
        postType: 'outfit',
        status: 'published',
        content: 'Post 1',
        likeCount: 5,
        isLiked: false,
        sharePath: '/community/posts/pub-test-1',
        createdAt: '',
        updatedAt: '',
      );
      repo.postDetail = initialPost;

      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final feedNotifier = container.read(communityFeedProvider.notifier);
      // Wait for feed to load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(feedNotifier.state.items.first.isLiked, isFalse);
      expect(feedNotifier.state.items.first.likeCount, 5);

      // Trigger like
      await feedNotifier.toggleLike('pub-test-1');

      // State is updated
      expect(feedNotifier.state.items.first.isLiked, isTrue);
      expect(feedNotifier.state.items.first.likeCount, 6);
      expect(repo.lastLikedPublicId, 'pub-test-1');
      expect(repo.lastIsLiked, isTrue);

      // Unlike
      await feedNotifier.toggleLike('pub-test-1');
      expect(feedNotifier.state.items.first.isLiked, isFalse);
      expect(feedNotifier.state.items.first.likeCount, 5);
      expect(repo.lastIsLiked, isFalse);
    });

    test('Optimistic like rolls back when network error occurs', () async {
      final repo = LikeTestCommunityRepository();
      const initialPost = Post(
        id: '1',
        publicId: 'pub-test-2',
        postType: 'outfit',
        status: 'published',
        content: 'Post 2',
        likeCount: 10,
        isLiked: false,
        sharePath: '/community/posts/pub-test-2',
        createdAt: '',
        updatedAt: '',
      );
      repo.postDetail = initialPost;
      repo.shouldThrowError = true; // Error injection

      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final feedNotifier = container.read(communityFeedProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(feedNotifier.state.items.first.isLiked, isFalse);
      expect(feedNotifier.state.items.first.likeCount, 10);

      // Attempt like -> throws and rolls back
      try {
        await feedNotifier.toggleLike('pub-test-2');
      } catch (_) {}

      // Verified rollback
      expect(feedNotifier.state.items.first.isLiked, isFalse);
      expect(feedNotifier.state.items.first.likeCount, 10);
    });

    test('PostDetailNotifier like optimistic toggle and rollback', () async {
      final repo = LikeTestCommunityRepository();
      const initialPost = Post(
        id: '1',
        publicId: 'pub-detail-1',
        postType: 'outfit',
        status: 'published',
        content: 'Post Detail',
        likeCount: 3,
        isLiked: false,
        sharePath: '/community/posts/pub-detail-1',
        createdAt: '',
        updatedAt: '',
      );
      repo.postDetail = initialPost;

      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final detailNotifier = container.read(postDetailProvider('pub-detail-1').notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(detailNotifier.state.post?.isLiked, isFalse);
      expect(detailNotifier.state.post?.likeCount, 3);

      // Like
      await detailNotifier.toggleLike();
      expect(detailNotifier.state.post?.isLiked, isTrue);
      expect(detailNotifier.state.post?.likeCount, 4);

      // Rollback test
      repo.shouldThrowError = true;
      try {
        await detailNotifier.toggleLike();
      } catch (_) {}
      expect(detailNotifier.state.post?.isLiked, isTrue);
      expect(detailNotifier.state.post?.likeCount, 4);
    });

    test('Parse getPostLikes paginated result into PaginationResult<CommunityUser>', () async {
      final json = {
        'items': [
          {
            'userId': 'u1',
            'username': 'fashionista',
            'firstName': 'Mai',
            'lastName': 'Phương',
          },
          {
            'userId': 'u2',
            'username': 'closy_guy',
            'gender': 1,
          },
        ],
        'metadata': {
          'page': 1,
          'limit': 20,
          'totalItems': 2,
          'totalPages': 1,
        },
      };

      final parsed = PaginationResult<CommunityUser>.fromJson(
        json,
        (item) => CommunityUser.fromJson(item as Map<String, dynamic>),
      );

      expect(parsed.items.length, 2);
      expect(parsed.items[0].displayName, 'Mai Phương');
      expect(parsed.items[1].username, 'closy_guy');
      expect(parsed.metadata.totalItems, 2);
      expect(parsed.metadata.hasMore, isFalse);
    });
  });
}
