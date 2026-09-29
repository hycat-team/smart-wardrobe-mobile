import 'community_user.dart';

class Comment {
  final String id;
  final CommunityUser? user;
  final String content;
  final String? parentCommentId;
  final int replyCount;
  final bool isDeleted;
  final String createdAt;

  const Comment({
    required this.id,
    this.user,
    required this.content,
    this.parentCommentId,
    this.replyCount = 0,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    CommunityUser? user;
    if (json['user'] is Map<String, dynamic>) {
      user = CommunityUser.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['author'] is Map<String, dynamic>) {
      user = CommunityUser.fromJson(json['author'] as Map<String, dynamic>);
    }

    return Comment(
      id: json['id']?.toString() ?? '',
      user: user,
      content: json['content']?.toString() ?? '',
      parentCommentId: json['parentCommentId']?.toString(),
      replyCount: json['replyCount'] is int
          ? json['replyCount'] as int
          : int.tryParse(json['replyCount']?.toString() ?? '0') ?? 0,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (user != null) 'user': user!.toJson(),
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'replyCount': replyCount,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
    };
  }

  Comment copyWith({
    String? id,
    CommunityUser? user,
    String? content,
    String? parentCommentId,
    int? replyCount,
    bool? isDeleted,
    String? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isRoot => parentCommentId == null || parentCommentId!.isEmpty;
  bool get isReply => !isRoot;

  /// Nội dung hiển thị: nếu bị xóa thì hiện placeholder
  String get displayContent {
    if (isDeleted) {
      return 'Bình luận đã bị xóa';
    }
    return content;
  }

  bool isOwnedBy(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return user?.userId == currentUserId;
  }
}
