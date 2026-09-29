import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../../shared/widgets/closy_toast.dart';
import '../../../../shared/widgets/media_viewer_overlay.dart';
import '../data/community_error.dart';
import '../data/community_repository.dart';
import '../models/comment_models.dart';
import '../models/post_models.dart';
import '../providers/comments_provider.dart';
import '../providers/community_feed_provider.dart';
import '../providers/post_detail_provider.dart';
import 'widgets/comment_tile.dart';
import 'widgets/community_user_avatar.dart';
import 'widgets/media_grid.dart';
import 'widgets/post_likes_sheet.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String publicId;
  final bool autoFocusComment;

  const PostDetailScreen({
    super.key,
    required this.publicId,
    this.autoFocusComment = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _commentFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa bài viết',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(communityRepositoryProvider).deletePost(widget.publicId);
        ref.read(communityFeedProvider.notifier).removePost(widget.publicId);
        if (mounted) {
          ClosyToast.success(context, 'Đã xóa bài viết thành công');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ClosyToast.error(context, extractCommunityErrorMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(postDetailProvider(widget.publicId));
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final post = detailState.post;
    final isOwner = post != null && post.isOwnedBy(currentUserId);
    final commentsState = ref.watch(commentsProvider(widget.publicId));
    final commentsNotifier = ref.read(commentsProvider(widget.publicId).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bài viết',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (post != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
              tooltip: 'Chia sẻ liên kết',
              onPressed: () {
                ClosyToast.info(context, 'Đã sao chép liên kết: ${post.sharePath}');
              },
            ),
            if (isOwner)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/community/create?editId=${post.publicId}');
                  } else if (value == 'delete') {
                    _handleDeletePost();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa bài', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
      bottomNavigationBar: post != null
          ? _buildCommentInputBar(commentsState, commentsNotifier)
          : null,
      body: detailState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          : detailState.isNotFound
              ? _buildNotFoundView()
              : detailState.errorMessage != null
                  ? _buildErrorView(detailState.errorMessage!)
                  : post == null
                      ? const SizedBox.shrink()
                      : _buildPostDetailContent(post, commentsState, commentsNotifier),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFEA),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.visibility_off_outlined, size: 38, color: AppColors.accentSandDark),
            ),
            const SizedBox(height: 18),
            Text(
              'Nội dung không khả dụng',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài viết này có thể đã bị xóa hoặc đã chuyển sang chế độ riêng tư.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Quay lại bảng tin'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(postDetailProvider(widget.publicId).notifier).loadDetail(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostDetailContent(
    Post post,
    CommentsState commentsState,
    CommentsNotifier commentsNotifier,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Row
          Row(
            children: [
              CommunityUserAvatar(
                user: post.user,
                size: 46,
                onTap: () {
                  final un = post.user?.username;
                  if (un != null && un.isNotEmpty) {
                    context.push('/users/$un');
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.user?.displayName ?? 'Thành viên Closy',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isHidden) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EFEA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border, width: 0.6),
                            ),
                            child: Text(
                              'Đã ẩn',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.user?.username != null && post.user!.username.isNotEmpty
                          ? '@${post.user!.username}'
                          : _formatDate(post.createdAt),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Tiêu đề
          if (post.title != null && post.title!.trim().isNotEmpty) ...[
            Text(
              post.title!.trim(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Nội dung văn bản
          if (post.content.trim().isNotEmpty) ...[
            Text(
              post.content.trim(),
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.5,
                color: AppColors.primary.withOpacity(0.9),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Media Grid / Video Player (Hoặc Hero Outfit Image nếu bài outfit không có media riêng)
          if (post.media.isNotEmpty) ...[
            MediaGrid(
              media: post.media,
              enableVideoPlayer: true,
            ),
            const SizedBox(height: 16),
          ] else if (post.isOutfit && post.outfit?.coverImageUrl != null && post.outfit!.coverImageUrl!.isNotEmpty) ...[
            // Bấm ảnh → mở ảnh toàn màn hình (đồng nhất bài ảnh thường).
            GestureDetector(
              onTap: () => openMediaViewer(
                context,
                imageUrls: [post.outfit!.coverImageUrl!],
                caption: post.outfit!.name,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: ClosyNetworkImage(
                    imageUrl: post.outfit!.coverImageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (post.isOutfit && post.outfit != null) ...[
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.style_outlined, color: AppColors.accentSandDark, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      post.outfit!.name,
                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6. Tương tác (Thích & Bình luận)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    final isAuth = ref.read(authStateProvider).isAuthenticated;
                    if (!isAuth) {
                      requireLogin(context, ref, message: 'Vui lòng đăng nhập để thích bài viết.');
                      return;
                    }
                    ref.read(postDetailProvider(widget.publicId).notifier).toggleLike();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: post.isLiked ? const Color(0xFFC85A54) : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            if (post.likeCount > 0) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => PostLikesSheet(publicId: post.publicId),
                              );
                            }
                          },
                          child: Text(
                            '${post.likeCount} lượt thích',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: post.isLiked ? const Color(0xFFC85A54) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentCount} bình luận',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 7. Khu vực bình luận (US4)
          Row(
            children: [
              Text(
                'BÌNH LUẬN (${post.commentCount})',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (commentsState.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCommentsSection(commentsState, commentsNotifier),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    CommentsState commentsState,
    CommentsNotifier commentsNotifier,
  ) {
    if (commentsState.roots.isEmpty && !commentsState.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Center(
          child: Text(
            'Chưa có bình luận nào. Hãy là người đầu tiên chia sẻ cảm nghĩ!',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final root in commentsState.roots) ...[
          CommentTile(
            comment: root,
            isReply: false,
            isExpanded: commentsState.expandedReplies.contains(root.id),
            isLoadingReplies: commentsState.loadingReplies.contains(root.id),
            onReply: () => _startReplyComment(root, commentsNotifier),
            onEdit: () => _startEditComment(root, commentsNotifier),
            onDelete: () => _handleDeleteComment(root, commentsNotifier),
            onToggleReplies: () => commentsNotifier.toggleReplies(root.id),
          ),
          // Render replies nếu expanded
          if (commentsState.expandedReplies.contains(root.id)) ...[
            for (final reply in (commentsState.repliesByRoot[root.id] ?? const <Comment>[]))
              CommentTile(
                comment: reply,
                isReply: true,
                onEdit: () => _startEditComment(reply, commentsNotifier),
                onDelete: () => _handleDeleteComment(reply, commentsNotifier),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildCommentInputBar(
    CommentsState commentsState,
    CommentsNotifier commentsNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replying to / Editing indicator banner
            if (commentsState.replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.surfaceSubtle,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đang trả lời @${commentsState.replyingTo!.user?.username ?? 'người dùng'}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentSandDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => commentsNotifier.setReplyingTo(null),
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else if (commentsState.editingComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.surfaceSubtle,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đang chỉnh sửa bình luận',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentSandDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        commentsNotifier.setEditingComment(null);
                        _commentController.clear();
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLength: 1000,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendComment(commentsNotifier),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: commentsState.replyingTo != null
                            ? 'Nhập câu trả lời...'
                            : commentsState.editingComment != null
                                ? 'Chỉnh sửa nội dung...'
                                : 'Thêm bình luận của bạn...',
                        hintStyle: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceSubtle,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: commentsState.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: commentsState.isSubmitting
                        ? null
                        : () => _handleSendComment(commentsNotifier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendComment(CommentsNotifier notifier) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      requireLogin(context, ref, message: 'Vui lòng đăng nhập để bình luận.');
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final commentsState = ref.read(commentsProvider(widget.publicId));
    bool success;
    if (commentsState.editingComment != null) {
      success = await notifier.updateComment(commentsState.editingComment!.id, text);
    } else {
      success = await notifier.sendComment(text);
    }

    if (success) {
      _commentController.clear();
      _commentFocusNode.unfocus();
    } else {
      final err = ref.read(commentsProvider(widget.publicId)).errorMessage ??
          'Không thể gửi bình luận. Vui lòng thử lại.';
      if (!mounted) return;
      ClosyToast.error(context, err);
    }
  }

  void _startEditComment(Comment comment, CommentsNotifier notifier) {
    notifier.setEditingComment(comment);
    _commentController.text = comment.content;
    _commentFocusNode.requestFocus();
  }

  void _startReplyComment(Comment comment, CommentsNotifier notifier) {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      requireLogin(context, ref, message: 'Vui lòng đăng nhập để trả lời bình luận.');
      return;
    }
    notifier.setReplyingTo(comment);
    _commentFocusNode.requestFocus();
  }

  Future<void> _handleDeleteComment(Comment comment, CommentsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa bình luận',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa bình luận này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteComment(comment);
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
