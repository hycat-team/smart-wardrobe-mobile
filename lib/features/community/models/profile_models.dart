import 'community_user.dart';

class PublicProfileStats {
  final int followerCount;
  final int followingCount;
  final int postCount;

  const PublicProfileStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
  });

  factory PublicProfileStats.fromJson(Map<String, dynamic> json) {
    return PublicProfileStats(
      followerCount: json['followerCount'] is int
          ? json['followerCount'] as int
          : int.tryParse(json['followerCount']?.toString() ?? '0') ?? 0,
      followingCount: json['followingCount'] is int
          ? json['followingCount'] as int
          : int.tryParse(json['followingCount']?.toString() ?? '0') ?? 0,
      postCount: json['postCount'] is int
          ? json['postCount'] as int
          : int.tryParse(json['postCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
    };
  }

  PublicProfileStats copyWith({
    int? followerCount,
    int? followingCount,
    int? postCount,
  }) {
    return PublicProfileStats(
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
    );
  }
}

class PublicProfile {
  final CommunityUser user;
  final PublicProfileStats stats;
  final bool isFollowing;
  final bool isMe;

  const PublicProfile({
    required this.user,
    required this.stats,
    this.isFollowing = false,
    this.isMe = false,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic>
        ? CommunityUser.fromJson(rawUser)
        : CommunityUser.fromJson(json);

    final rawStats = json['stats'];
    final stats = rawStats is Map<String, dynamic>
        ? PublicProfileStats.fromJson(rawStats)
        : const PublicProfileStats();

    return PublicProfile(
      user: user,
      stats: stats,
      isFollowing: json['isFollowing'] == true,
      isMe: json['isMe'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
      'isFollowing': isFollowing,
      'isMe': isMe,
    };
  }

  PublicProfile copyWith({
    CommunityUser? user,
    PublicProfileStats? stats,
    bool? isFollowing,
    bool? isMe,
  }) {
    return PublicProfile(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe ?? this.isMe,
    );
  }
}

class FollowUser {
  final CommunityUser user;
  final String relation; // 'following' | 'follower'
  final String followedAt;

  const FollowUser({
    required this.user,
    required this.relation,
    required this.followedAt,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic>
        ? CommunityUser.fromJson(rawUser)
        : CommunityUser.fromJson(json);

    return FollowUser(
      user: user,
      relation: (json['relation']?.toString() ?? 'follower').toLowerCase(),
      followedAt: json['followedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'relation': relation,
      'followedAt': followedAt,
    };
  }

  bool get isFollowingRelation => relation == 'following';
  bool get isFollowerRelation => relation == 'follower';
}
