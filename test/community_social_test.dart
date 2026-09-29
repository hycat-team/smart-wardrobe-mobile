import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/user_social_repository.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/models/profile_models.dart';
import 'package:smart_wardrobe/features/community/models/search_models.dart';
import 'package:smart_wardrobe/features/community/providers/user_social_provider.dart';

class SocialTestRepository extends UserSocialRepository {
  bool shouldThrowError = false;
  String? lastFollowedUsername;
  bool? lastIsFollowing;
  PublicProfile? profileToReturn;
  List<Post> postsToReturn = [];

  @override
  Future<void> followUser(String username, {required bool isFollowing}) async {
    lastFollowedUsername = username;
    lastIsFollowing = isFollowing;
    if (shouldThrowError) {
      throw Exception('Network error');
    }
  }

  @override
  Future<PublicProfile> getPublicProfile(String username) async {
    if (profileToReturn != null) return profileToReturn!;
    return PublicProfile(
      user: CommunityUser(userId: 'u1', username: username),
      stats: const PublicProfileStats(followerCount: 10, followingCount: 5, postCount: 2),
      isFollowing: false,
      isMe: false,
    );
  }

  @override
  Future<PaginationResult<Post>> getUserPosts(
    String username, {
    int page = 1,
    int limit = 20,
  }) async {
    return PaginationResult<Post>(
      items: postsToReturn,
      metadata: PaginationMetadata(
        page: page,
        limit: limit,
        totalItems: postsToReturn.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<PaginationResult<FollowUser>> getUserFollows(
    String username, {
    String? type = 'following',
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginationResult<FollowUser>(
      items: const [
        FollowUser(
          user: CommunityUser(userId: 'u2', username: 'friend1'),
          relation: 'following',
          followedAt: '2026-09-27T10:00:00Z',
        ),
      ],
      metadata: const PaginationMetadata(
        page: 1,
        limit: 20,
        totalItems: 1,
        totalPages: 1,
      ),
    );
  }
}

void main() {
  group('Community Social & Profile Tests (US5)', () {
    test('Parse PublicProfile with nested user and stats', () {
      final json = {
        'user': {
          'userId': 'usr_123',
          'username': 'fashion_icon',
          'firstName': 'Elena',
          'lastName': 'Vu',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'gender': 2,
        },
        'stats': {
          'followerCount': 120,
          'followingCount': 85,
          'postCount': 34,
        },
        'isFollowing': true,
        'isMe': false,
      };

      final profile = PublicProfile.fromJson(json);

      expect(profile.user.userId, 'usr_123');
      expect(profile.user.username, 'fashion_icon');
      expect(profile.user.displayName, 'Elena Vu');
      expect(profile.stats.followerCount, 120);
      expect(profile.stats.followingCount, 85);
      expect(profile.stats.postCount, 34);
      expect(profile.isFollowing, isTrue);
      expect(profile.isMe, isFalse);
    });

    test('Parse FollowUser with nested user, relation, and followedAt', () {
      final json = {
        'user': {
          'userId': 'usr_456',
          'username': 'minimalist',
        },
        'relation': 'follower',
        'followedAt': '2026-09-27T08:30:00Z',
      };

      final followUser = FollowUser.fromJson(json);

      expect(followUser.user.userId, 'usr_456');
      expect(followUser.user.username, 'minimalist');
      expect(followUser.relation, 'follower');
      expect(followUser.isFollowerRelation, isTrue);
      expect(followUser.isFollowingRelation, isFalse);
      expect(followUser.followedAt, '2026-09-27T08:30:00Z');
    });

    test('PublicProfileNotifier optimistic follow and rollback on failure', () async {
      final repo = SocialTestRepository();
      repo.profileToReturn = const PublicProfile(
        user: CommunityUser(userId: 'u1', username: 'style_guru'),
        stats: PublicProfileStats(followerCount: 50, followingCount: 20, postCount: 5),
        isFollowing: false,
        isMe: false,
      );

      final container = ProviderContainer(
        overrides: [
          userSocialRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(publicProfileProvider('style_guru').notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.profile?.isFollowing, isFalse);
      expect(notifier.state.profile?.stats.followerCount, 50);

      // Follow optimistically
      await notifier.toggleFollow();
      expect(notifier.state.profile?.isFollowing, isTrue);
      expect(notifier.state.profile?.stats.followerCount, 51);
      expect(repo.lastFollowedUsername, 'style_guru');
      expect(repo.lastIsFollowing, isTrue);

      // Trigger error on unfollow -> rolls back
      repo.shouldThrowError = true;
      try {
        await notifier.toggleFollow();
      } catch (_) {}

      // Rollback verified
      expect(notifier.state.profile?.isFollowing, isTrue);
      expect(notifier.state.profile?.stats.followerCount, 51);
    });

    test('PublicProfileNotifier does not follow self (isMe = true)', () async {
      final repo = SocialTestRepository();
      repo.profileToReturn = const PublicProfile(
        user: CommunityUser(userId: 'u_self', username: 'my_profile'),
        stats: PublicProfileStats(followerCount: 10, followingCount: 10, postCount: 2),
        isFollowing: false,
        isMe: true,
      );

      final container = ProviderContainer(
        overrides: [
          userSocialRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(publicProfileProvider('my_profile').notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.profile?.isMe, isTrue);

      // Call toggleFollow -> should be a no-op
      await notifier.toggleFollow();
      expect(notifier.state.profile?.isFollowing, isFalse);
      expect(repo.lastFollowedUsername, isNull);
    });
  });
}
