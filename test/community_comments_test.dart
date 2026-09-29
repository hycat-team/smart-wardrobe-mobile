import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/models/comment_models.dart';
import 'package:smart_wardrobe/features/community/models/community_user.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/providers/comments_provider.dart';

class FakeCommentsRepository extends CommunityRepository {
  List<Comment> roots = [];
  Map<String, List<Comment>> replies = {};

  @override
  Future<List<Comment>> getPostComments(String publicId) async {
    return roots;
  }

  @override
  Future<List<Comment>> getCommentReplies(String publicId, String commentId) async {
    return replies[commentId] ?? [];
  }

  @override
  Future<Comment> addComment(
    String publicId, {
    required String content,
    String? parentCommentId,
  }) async {
    return Comment(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      user: const CommunityUser(userId: 'u1', username: 'tester'),
      content: content,
      parentCommentId: parentCommentId,
      replyCount: 0,
      isDeleted: false,
      createdAt: '2026-09-27T12:00:00Z',
    );
  }

  @override
  Future<Comment> updateComment(
    String publicId,
    String commentId, {
    required String content,
  }) async {
    return Comment(
      id: commentId,
      content: content,
      createdAt: '2026-09-27T12:00:00Z',
    );
  }

  @override
  Future<void> deleteComment(String publicId, String commentId) async {}

  @override
  Future<Post> getPostDetail(String publicId) async {
    return Post(
      id: '1',
      publicId: publicId,
      postType: 'outfit',
      status: 'published',
      content: 'Post',
      commentCount: 0,
      sharePath: '/community/posts/$publicId',
      createdAt: '',
      updatedAt: '',
    );
  }
}

void main() {
  group('Hierarchical Comments Tests (US4)', () {
    test('Roots ordering: newly posted root comments are inserted at index 0 (mới -> cũ)', () async {
      final repo = FakeCommentsRepository();
      repo.roots = [
        const Comment(id: 'c1', content: 'Root cũ', createdAt: '2026-09-27T10:00:00Z'),
      ];

      final notifier = CommentsNotifier(repo, null, 'pub-1');
      await Future.delayed(const Duration(milliseconds: 30));

      expect(notifier.state.roots.length, 1);
      expect(notifier.state.roots.first.content, 'Root cũ');

      // Post new root comment
      await notifier.sendComment('Root mới');

      // Newly posted comment must be first in list
      expect(notifier.state.roots.length, 2);
      expect(notifier.state.roots[0].content, 'Root mới');
      expect(notifier.state.roots[1].content, 'Root cũ');
    });

    test('Replies ordering: replies to root are appended to list (cũ -> mới) and increments replyCount', () async {
      final repo = FakeCommentsRepository();
      const root = Comment(id: 'r1', content: 'Root comment', replyCount: 0, createdAt: '');
      repo.roots = [root];

      final notifier = CommentsNotifier(repo, null, 'pub-1');
      await Future.delayed(const Duration(milliseconds: 30));

      // Reply to root
      notifier.setReplyingTo(root);
      await notifier.sendComment('Reply 1');

      expect(notifier.state.roots.first.replyCount, 1);
      final rList1 = notifier.state.repliesByRoot['r1']!;
      expect(rList1.length, 1);
      expect(rList1[0].content, 'Reply 1');

      // Reply 2 to root
      notifier.setReplyingTo(root);
      await notifier.sendComment('Reply 2');

      expect(notifier.state.roots.first.replyCount, 2);
      final rList2 = notifier.state.repliesByRoot['r1']!;
      expect(rList2.length, 2);
      // Older reply first, newer appended
      expect(rList2[0].content, 'Reply 1');
      expect(rList2[1].content, 'Reply 2');
    });

    test('Deleted root with replies is marked isDeleted with placeholder, without replies is removed', () async {
      final repo = FakeCommentsRepository();
      const rootWithReplies = Comment(
        id: 'r-with-replies',
        content: 'Original content',
        replyCount: 1,
        createdAt: '',
      );
      const rootWithoutReplies = Comment(
        id: 'r-no-replies',
        content: 'Solo comment',
        replyCount: 0,
        createdAt: '',
      );

      repo.roots = [rootWithReplies, rootWithoutReplies];

      final notifier = CommentsNotifier(repo, null, 'pub-1');
      await Future.delayed(const Duration(milliseconds: 30));

      // 1. Delete rootWithReplies
      await notifier.deleteComment(rootWithReplies);
      final deletedRoot = notifier.state.roots.firstWhere((r) => r.id == 'r-with-replies');
      expect(deletedRoot.isDeleted, isTrue);
      expect(deletedRoot.content, '');
      expect(deletedRoot.displayContent, 'Bình luận đã bị xóa');

      // 2. Delete rootWithoutReplies -> removed from list completely
      await notifier.deleteComment(rootWithoutReplies);
      expect(notifier.state.roots.any((r) => r.id == 'r-no-replies'), isFalse);
    });

    test('Deleting reply decrements root replyCount and removes root if already isDeleted with 0 replies', () async {
      final repo = FakeCommentsRepository();
      const deletedRoot = Comment(
        id: 'r-ghost',
        content: '',
        isDeleted: true,
        replyCount: 1,
        createdAt: '',
      );
      const childReply = Comment(
        id: 'reply-1',
        parentCommentId: 'r-ghost',
        content: 'I am the only reply',
        createdAt: '',
      );
      repo.roots = [deletedRoot];
      repo.replies = {
        'r-ghost': [childReply],
      };

      final notifier = CommentsNotifier(repo, null, 'pub-1');
      await Future.delayed(const Duration(milliseconds: 30));
      await notifier.toggleReplies('r-ghost');

      expect(notifier.state.repliesByRoot['r-ghost']?.length, 1);

      // Delete the only child reply
      await notifier.deleteComment(childReply);

      // Because root was isDeleted and now has 0 replies, it should be cleaned up!
      expect(notifier.state.roots.any((r) => r.id == 'r-ghost'), isFalse);
    });
  });
}
