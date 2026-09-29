import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/models/search_models.dart';
import 'package:smart_wardrobe/features/community/providers/community_feed_provider.dart';

class FakeCommunityRepository extends CommunityRepository {
  List<Post> returnPosts = [];
  bool hasMore = false;
  int total = 0;

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
      items: returnPosts,
      metadata: PaginationMetadata(
        page: page,
        limit: limit,
        totalItems: total,
        totalPages: hasMore ? page + 1 : page,
      ),
    );
  }
}

void main() {
  group('Community Model Parsing & Logic Tests (US1)', () {
    test('Post.fromJson parses nested user, lowercase type, media and getters', () {
      final json = {
        'id': 'post-123',
        'publicId': 'pub-abc-123',
        'user': {
          'userId': 'usr-1',
          'username': 'thanhhang',
          'firstName': 'Hằng',
          'lastName': 'Nguyễn',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'gender': 2,
        },
        'postType': 'OUTFIT',
        'status': 'PUBLISHED',
        'title': 'Set đồ dạo phố mùa thu',
        'content': 'Một outfit nhẹ nhàng cho cuối tuần.',
        'outfit': {
          'id': 'outfit-99',
          'name': 'Parisian Chic',
          'coverImageUrl': 'https://example.com/outfit.jpg',
        },
        'likeCount': 15,
        'commentCount': 3,
        'isLiked': true,
        'isFollowingAuthor': false,
        'sharePath': '/community/posts/pub-abc-123',
        'media': [
          {
            'id': 'm-2',
            'mediaType': 'VIDEO',
            'mediaUrl': 'https://example.com/video.mp4',
            'sortOrder': 2,
          },
          {
            'id': 'm-1',
            'mediaType': 'IMAGE',
            'mediaUrl': 'https://example.com/img1.jpg',
            'sortOrder': 1,
          },
        ],
        'createdAt': '2026-09-27T10:00:00Z',
        'updatedAt': '2026-09-27T10:00:00Z',
      };

      final post = Post.fromJson(json);

      expect(post.id, 'post-123');
      expect(post.publicId, 'pub-abc-123');
      expect(post.postType, 'outfit');
      expect(post.status, 'published');
      expect(post.isOutfit, isTrue);
      expect(post.isMedia, isFalse);
      expect(post.isHidden, isFalse);
      expect(post.likeCount, 15);
      expect(post.isLiked, isTrue);
      expect(post.outfit?.name, 'Parisian Chic');
      expect(post.coverImageUrl, 'https://example.com/outfit.jpg');

      // User getters
      final user = post.user!;
      expect(user.displayName, 'Hằng Nguyễn');
      expect(user.initials, 'HN');
      expect(user.genderLabel, 'Nữ');

      // Media sorted by sortOrder
      expect(post.media.length, 2);
      expect(post.media[0].id, 'm-1');
      expect(post.media[0].mediaType, 'image');
      expect(post.media[0].isImage, isTrue);
      expect(post.media[1].id, 'm-2');
      expect(post.media[1].mediaType, 'video');
      expect(post.media[1].isVideo, isTrue);

      // isOwnedBy
      expect(post.isOwnedBy('usr-1'), isTrue);
      expect(post.isOwnedBy('usr-other'), isFalse);
    });

    test('Post.fromJson handles hidden status and author badge', () {
      final json = {
        'id': 'post-hidden',
        'publicId': 'pub-hidden',
        'postType': 'media',
        'status': 'hidden',
        'content': 'Bài viết riêng tư',
        'sharePath': '/community/posts/pub-hidden',
        'createdAt': '2026-09-27T11:00:00Z',
        'updatedAt': '2026-09-27T11:00:00Z',
      };

      final post = Post.fromJson(json);
      expect(post.isHidden, isTrue);
      expect(post.isMedia, isTrue);
      expect(post.content, 'Bài viết riêng tư');
    });

    test('CommunityUser displayName and initials fallbacks', () {
      // Case 1: First & Last
      const u1 = CommunityUser(userId: '1', username: 'user1', firstName: 'Lan', lastName: 'Mai');
      expect(u1.displayName, 'Lan Mai');
      expect(u1.initials, 'LM');

      // Case 2: Only username
      const u2 = CommunityUser(userId: '2', username: 'closy_fan');
      expect(u2.displayName, 'closy_fan');
      expect(u2.initials, 'CL');

      // Case 3: Empty
      const u3 = CommunityUser(userId: '3', username: '');
      expect(u3.displayName, 'Thành viên Closy');
      expect(u3.initials, 'CL');
    });
  });

  group('CommunityFeedNotifier Tests (US1)', () {
    test('Feed loads items and loadMore dedupes by publicId', () async {
      final fakeRepo = FakeCommunityRepository();
      const p1 = Post(
        id: '1',
        publicId: 'pub-1',
        postType: 'outfit',
        status: 'published',
        content: 'Post 1',
        sharePath: '/community/posts/pub-1',
        createdAt: '',
        updatedAt: '',
      );
      const p2 = Post(
        id: '2',
        publicId: 'pub-2',
        postType: 'media',
        status: 'published',
        content: 'Post 2',
        sharePath: '/community/posts/pub-2',
        createdAt: '',
        updatedAt: '',
      );

      fakeRepo.returnPosts = [p1, p2];
      fakeRepo.hasMore = true;
      fakeRepo.total = 3;

      final notifier = CommunityFeedNotifier(fakeRepo);
      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.items.length, 2);
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isTrue);

      // Page 2 returns duplicate p2 and fresh p3
      const p3 = Post(
        id: '3',
        publicId: 'pub-3',
        postType: 'media',
        status: 'published',
        content: 'Post 3',
        sharePath: '/community/posts/pub-3',
        createdAt: '',
        updatedAt: '',
      );
      fakeRepo.returnPosts = [p2, p3]; // p2 is duplicate!
      fakeRepo.hasMore = false;

      await notifier.loadMore();

      // Total items should be 3 (not 4) because p2 was deduped
      expect(notifier.state.items.length, 3);
      expect(notifier.state.items.map((p) => p.publicId).toList(), ['pub-1', 'pub-2', 'pub-3']);
      expect(notifier.state.hasMore, isFalse);
    });

    test('Feed removePost and updatePost work properly', () async {
      final fakeRepo = FakeCommunityRepository();
      const p1 = Post(
        id: '1',
        publicId: 'pub-1',
        postType: 'outfit',
        status: 'published',
        content: 'Post 1',
        sharePath: '/community/posts/pub-1',
        createdAt: '',
        updatedAt: '',
      );
      fakeRepo.returnPosts = [p1];
      final notifier = CommunityFeedNotifier(fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.items.length, 1);

      // Update post content
      final updatedP1 = p1.copyWith(content: 'Updated content');
      notifier.updatePost(updatedP1);
      expect(notifier.state.items.first.content, 'Updated content');

      // Remove post
      notifier.removePost('pub-1');
      expect(notifier.state.items.isEmpty, isTrue);
    });
  });
}
