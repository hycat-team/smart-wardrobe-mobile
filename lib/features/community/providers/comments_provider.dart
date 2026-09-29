import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/comment_models.dart';
import 'post_detail_provider.dart';

class CommentsState {
  final List<Comment> roots;
  final Map<String, List<Comment>> repliesByRoot;
  final Set<String> loadingReplies;
  final Set<String> expandedReplies;
  final bool isLoading;
  final bool isSubmitting;
  final Comment? replyingTo;
  final Comment? editingComment;
  final String? errorMessage;

  const CommentsState({
    this.roots = const [],
    this.repliesByRoot = const {},
    this.loadingReplies = const {},
    this.expandedReplies = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.replyingTo,
    this.editingComment,
    this.errorMessage,
  });

  CommentsState copyWith({
    List<Comment>? roots,
    Map<String, List<Comment>>? repliesByRoot,
    Set<String>? loadingReplies,
    Set<String>? expandedReplies,
    bool? isLoading,
    bool? isSubmitting,
    Comment? replyingTo,
    bool clearReplyingTo = false,
    Comment? editingComment,
    bool clearEditingComment = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommentsState(
      roots: roots ?? this.roots,
      repliesByRoot: repliesByRoot ?? this.repliesByRoot,
      loadingReplies: loadingReplies ?? this.loadingReplies,
      expandedReplies: expandedReplies ?? this.expandedReplies,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      editingComment:
          clearEditingComment ? null : (editingComment ?? this.editingComment),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommunityRepository _repository;
  final Ref? _ref;
  final String publicId;

  CommentsNotifier(this._repository, this._ref, this.publicId)
      : super(const CommentsState()) {
    loadRoots();
  }

  /// Tải danh sách bình luận gốc (mới -> cũ)
  Future<void> loadRoots() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final roots = await _repository.getPostComments(publicId);
      if (!mounted) return;
      state = state.copyWith(
        roots: roots,
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

  /// Tải phản hồi cho 1 bình luận gốc (cũ -> mới)
  Future<void> toggleReplies(String rootId) async {
    final expanded = Set<String>.from(state.expandedReplies);
    if (expanded.contains(rootId)) {
      expanded.remove(rootId);
      state = state.copyWith(expandedReplies: expanded);
      return;
    }

    expanded.add(rootId);
    state = state.copyWith(expandedReplies: expanded);

    // Nếu đã tải trước đó rồi thì chỉ mở rộng
    if (state.repliesByRoot.containsKey(rootId)) return;

    final loading = Set<String>.from(state.loadingReplies)..add(rootId);
    state = state.copyWith(loadingReplies: loading);

    try {
      final replies = await _repository.getCommentReplies(publicId, rootId);
      final map = Map<String, List<Comment>>.from(state.repliesByRoot);
      map[rootId] = replies;

      final updatedLoading = Set<String>.from(state.loadingReplies)..remove(rootId);
      state = state.copyWith(
        repliesByRoot: map,
        loadingReplies: updatedLoading,
      );
    } catch (e) {
      final updatedLoading = Set<String>.from(state.loadingReplies)..remove(rootId);
      state = state.copyWith(
        loadingReplies: updatedLoading,
        errorMessage: extractCommunityErrorMessage(e),
      );
    }
  }

  void setReplyingTo(Comment? comment) {
    state = state.copyWith(
      replyingTo: comment,
      clearReplyingTo: comment == null,
      clearEditingComment: true,
    );
  }

  void setEditingComment(Comment? comment) {
    state = state.copyWith(
      editingComment: comment,
      clearEditingComment: comment == null,
      clearReplyingTo: true,
    );
  }

  /// Gửi bình luận mới hoặc phản hồi
  Future<bool> sendComment(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final parentId = state.replyingTo?.id;
      final newComment = await _repository.addComment(
        publicId,
        content: trimmed,
        parentCommentId: parentId,
      );

      if (parentId == null) {
        // Bình luận gốc mới -> chèn lên đầu (mới -> cũ)
        state = state.copyWith(
          roots: [newComment, ...state.roots],
          isSubmitting: false,
          clearReplyingTo: true,
        );
      } else {
        // Phản hồi -> thêm vào cuối danh sách phản hồi (cũ -> mới)
        final map = Map<String, List<Comment>>.from(state.repliesByRoot);
        final existingReplies = map[parentId] ?? [];
        map[parentId] = [...existingReplies, newComment];

        // Tăng replyCount của gốc
        final updatedRoots = state.roots.map((r) {
          if (r.id == parentId) {
            return r.copyWith(replyCount: r.replyCount + 1);
          }
          return r;
        }).toList();

        final expanded = Set<String>.from(state.expandedReplies)..add(parentId);

        state = state.copyWith(
          roots: updatedRoots,
          repliesByRoot: map,
          expandedReplies: expanded,
          isSubmitting: false,
          clearReplyingTo: true,
        );
      }

      // Cập nhật tổng commentCount trên detail
      if (_ref != null) {
        try {
          _ref?.read(postDetailProvider(publicId).notifier).updateCommentCount(1);
        } catch (_) {}
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: extractCommunityErrorMessage(e),
      );
      return false;
    }
  }

  /// Chỉnh sửa nội dung bình luận
  Future<bool> updateComment(String commentId, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final updated = await _repository.updateComment(publicId, commentId, content: trimmed);

      // Cập nhật trong roots nếu là gốc
      final updatedRoots = state.roots.map((r) {
        if (r.id == commentId) return updated;
        return r;
      }).toList();

      // Cập nhật trong replies nếu là con
      final map = Map<String, List<Comment>>.from(state.repliesByRoot);
      for (final key in map.keys) {
        final list = map[key]!;
        final idx = list.indexWhere((c) => c.id == commentId);
        if (idx != -1) {
          final copyList = [...list];
          copyList[idx] = updated;
          map[key] = copyList;
          break;
        }
      }

      state = state.copyWith(
        roots: updatedRoots,
        repliesByRoot: map,
        isSubmitting: false,
        clearEditingComment: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: extractCommunityErrorMessage(e),
      );
      return false;
    }
  }

  /// Xóa bình luận
  Future<void> deleteComment(Comment comment) async {
    try {
      await _repository.deleteComment(publicId, comment.id);

      if (comment.isRoot) {
        if (comment.replyCount > 0) {
          // Gốc bị xóa còn reply -> isDeleted = true, content = ''
          final updatedRoots = state.roots.map((r) {
            if (r.id == comment.id) {
              return r.copyWith(isDeleted: true, content: '');
            }
            return r;
          }).toList();
          state = state.copyWith(roots: updatedRoots);
        } else {
          // Gốc không còn reply -> xóa hẳn
          final updatedRoots = state.roots.where((r) => r.id != comment.id).toList();
          state = state.copyWith(roots: updatedRoots);
        }
      } else {
        // Là reply -> xóa khỏi danh sách replies của root
        final parentId = comment.parentCommentId;
        if (parentId != null) {
          final map = Map<String, List<Comment>>.from(state.repliesByRoot);
          final existing = map[parentId] ?? [];
          final filtered = existing.where((c) => c.id != comment.id).toList();
          map[parentId] = filtered;

          // Giảm replyCount của root
          var updatedRoots = state.roots.map((r) {
            if (r.id == parentId) {
              return r.copyWith(replyCount: (r.replyCount - 1).clamp(0, 999999));
            }
            return r;
          }).toList();

          // Nếu root đã isDeleted và không còn reply nào -> xóa root luôn
          final root = updatedRoots.firstWhere((r) => r.id == parentId, orElse: () => comment);
          if (root.isDeleted && root.replyCount == 0) {
            updatedRoots = updatedRoots.where((r) => r.id != parentId).toList();
            map.remove(parentId);
          }

          state = state.copyWith(
            roots: updatedRoots,
            repliesByRoot: map,
          );
        }
      }

      // Giảm commentCount trên detail
      if (_ref != null) {
        try {
          _ref?.read(postDetailProvider(publicId).notifier).updateCommentCount(-1);
        } catch (_) {}
      }
    } catch (e) {
      state = state.copyWith(errorMessage: extractCommunityErrorMessage(e));
    }
  }
}

final commentsProvider =
    StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
        (ref, publicId) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommentsNotifier(repo, ref, publicId);
});
