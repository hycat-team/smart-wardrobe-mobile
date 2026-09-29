import 'community_user.dart';

class OutfitBrief {
  final String id;
  final String name;
  final String? coverImageUrl;

  const OutfitBrief({
    required this.id,
    required this.name,
    this.coverImageUrl,
  });

  factory OutfitBrief.fromJson(Map<String, dynamic> json) {
    return OutfitBrief(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl']?.toString() ?? json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    };
  }
}

class PostMedia {
  final String id;
  final String mediaType; // 'image' | 'video'
  final String mediaUrl;
  final String? publicId;
  final int sortOrder;
  final int? bytes;
  final double? durationSeconds;

  const PostMedia({
    required this.id,
    required this.mediaType,
    required this.mediaUrl,
    this.publicId,
    required this.sortOrder,
    this.bytes,
    this.durationSeconds,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id']?.toString() ?? '',
      mediaType: (json['mediaType']?.toString() ?? 'image').toLowerCase(),
      mediaUrl: json['mediaUrl']?.toString() ?? json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      bytes: json['bytes'] is int
          ? json['bytes'] as int
          : int.tryParse(json['bytes']?.toString() ?? ''),
      durationSeconds: json['durationSeconds'] != null
          ? (json['durationSeconds'] as num).toDouble()
          : (json['duration'] != null ? (json['duration'] as num).toDouble() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      if (publicId != null) 'publicId': publicId,
      'sortOrder': sortOrder,
      if (bytes != null) 'bytes': bytes,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
}

class Post {
  final String id;
  final String publicId;
  final CommunityUser? user;
  final String postType; // 'outfit' | 'media'
  final String status; // 'published' | 'hidden' | 'deleted'
  final String? title;
  final String content;
  final OutfitBrief? outfit;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowingAuthor;
  final String sharePath;
  final List<PostMedia> media;
  final String createdAt;
  final String updatedAt;

  const Post({
    required this.id,
    required this.publicId,
    this.user,
    required this.postType,
    required this.status,
    this.title,
    required this.content,
    this.outfit,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isFollowingAuthor = false,
    required this.sharePath,
    this.media = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    CommunityUser? user;
    if (json['user'] is Map<String, dynamic>) {
      user = CommunityUser.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['author'] is Map<String, dynamic>) {
      user = CommunityUser.fromJson(json['author'] as Map<String, dynamic>);
    }

    OutfitBrief? outfit;
    if (json['outfit'] is Map<String, dynamic>) {
      outfit = OutfitBrief.fromJson(json['outfit'] as Map<String, dynamic>);
    }

    final rawMedia = json['media'];
    final mediaList = <PostMedia>[];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map<String, dynamic>) {
          mediaList.add(PostMedia.fromJson(m));
        }
      }
      mediaList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final pubId = json['publicId']?.toString() ?? json['id']?.toString() ?? '';

    return Post(
      id: json['id']?.toString() ?? '',
      publicId: pubId,
      user: user,
      postType: (json['postType']?.toString() ?? 'outfit').toLowerCase(),
      status: (json['status']?.toString() ?? 'published').toLowerCase(),
      title: json['title']?.toString(),
      content: json['content']?.toString() ?? '',
      outfit: outfit,
      likeCount: json['likeCount'] is int
          ? json['likeCount'] as int
          : int.tryParse(json['likeCount']?.toString() ?? '0') ?? 0,
      commentCount: json['commentCount'] is int
          ? json['commentCount'] as int
          : int.tryParse(json['commentCount']?.toString() ?? '0') ?? 0,
      isLiked: json['isLiked'] == true,
      isFollowingAuthor: json['isFollowingAuthor'] == true,
      sharePath: json['sharePath']?.toString() ?? '/community/posts/$pubId',
      media: mediaList,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicId': publicId,
      if (user != null) 'user': user!.toJson(),
      'postType': postType,
      'status': status,
      if (title != null) 'title': title,
      'content': content,
      if (outfit != null) 'outfit': outfit!.toJson(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'isFollowingAuthor': isFollowingAuthor,
      'sharePath': sharePath,
      'media': media.map((m) => m.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Post copyWith({
    String? id,
    String? publicId,
    CommunityUser? user,
    String? postType,
    String? status,
    String? title,
    String? content,
    OutfitBrief? outfit,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFollowingAuthor,
    String? sharePath,
    List<PostMedia>? media,
    String? createdAt,
    String? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      user: user ?? this.user,
      postType: postType ?? this.postType,
      status: status ?? this.status,
      title: title ?? this.title,
      content: content ?? this.content,
      outfit: outfit ?? this.outfit,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      sharePath: sharePath ?? this.sharePath,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ảnh đại diện/bìa: outfit cover -> ảnh media đầu tiên -> null
  String? get coverImageUrl {
    if (outfit?.coverImageUrl != null && outfit!.coverImageUrl!.isNotEmpty) {
      return outfit!.coverImageUrl;
    }
    for (final m in media) {
      if (m.isImage && m.mediaUrl.isNotEmpty) {
        return m.mediaUrl;
      }
    }
    if (media.isNotEmpty && media.first.mediaUrl.isNotEmpty) {
      return media.first.mediaUrl;
    }
    return null;
  }

  bool get hasMedia => media.isNotEmpty;
  bool get isHidden => status == 'hidden';
  bool get isOutfit => postType == 'outfit';
  bool get isMedia => postType == 'media';

  bool isOwnedBy(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return user?.userId == currentUserId;
  }
}

class PostMediaReq {
  final String mediaType; // 'image' | 'video'
  final String mediaUrl;
  final String? publicId;
  final int sortOrder;
  final int? bytes;
  final double? durationSeconds;

  const PostMediaReq({
    required this.mediaType,
    required this.mediaUrl,
    this.publicId,
    required this.sortOrder,
    this.bytes,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      if (publicId != null) 'publicId': publicId,
      'sortOrder': sortOrder,
      if (bytes != null && bytes! > 0) 'bytes': bytes,
      if (durationSeconds != null && durationSeconds! > 0) 'durationSeconds': durationSeconds,
    };
  }
}

class CreatePostReq {
  final String postType; // 'outfit' | 'media'
  final String? title;
  final String content;
  final String? outfitId;
  final List<PostMediaReq>? media;

  const CreatePostReq({
    required this.postType,
    this.title,
    required this.content,
    this.outfitId,
    this.media,
  });

  Map<String, dynamic> toJson() {
    return {
      'postType': postType,
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      'content': content.trim(),
      if (outfitId != null && outfitId!.isNotEmpty) 'outfitId': outfitId,
      if (media != null && media!.isNotEmpty)
        'media': media!.map((m) => m.toJson()).toList(),
    };
  }
}

class UpdatePostReq {
  final String? title;
  final String? content;
  final String? outfitId;
  final List<PostMediaReq>? media;

  const UpdatePostReq({
    this.title,
    this.content,
    this.outfitId,
    this.media,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title!.trim(),
      if (content != null) 'content': content!.trim(),
      if (outfitId != null && outfitId!.isNotEmpty) 'outfitId': outfitId,
      if (media != null) 'media': media!.map((m) => m.toJson()).toList(),
    };
  }
}
