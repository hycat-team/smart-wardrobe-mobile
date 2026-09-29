import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../../../shared/widgets/closy_toast.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/community_error.dart';
import '../../models/post_models.dart';
import '../../../../shared/widgets/media_viewer_overlay.dart';
import '../widgets/community_user_avatar.dart';
import '../widgets/media_grid.dart';
import '../widgets/post_likes_sheet.dart';

class PostCard extends ConsumerWidget {
  final Post post;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeToggle,
    this.onCommentTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isOwner = post.isOwnedBy(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Avatar, Tên, Ngày, Badge ẩn, Menu)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                CommunityUserAvatar(
                  user: post.user,
                  size: 40,
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
                                fontSize: 14,
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
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
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
            ),
          ),

          // 2. Nội dung bài viết (Tiêu đề + text)
          InkWell(
            onTap: () => context.push('/community/posts/${post.publicId}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.title != null && post.title!.trim().isNotEmpty) ...[
                    Text(
                      post.title!.trim(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (post.content.trim().isNotEmpty) ...[
                    Text(
                      post.content.trim(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5,
                        color: AppColors.primary.withOpacity(0.85),
                        height: 1.45,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          // 3. Media Grid hoặc Outfit Hero Image (nếu bài outfit không có media riêng)
          if (post.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MediaGrid(
                media: post.media,
                enableVideoPlayer: false,
              ),
            )
          else if (post.isOutfit && post.outfit?.coverImageUrl != null && post.outfit!.coverImageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Bấm ảnh → mở ảnh toàn màn hình (như bài ảnh thông thường).
                      GestureDetector(
                        onTap: () => openMediaViewer(
                          context,
                          imageUrls: [post.outfit!.coverImageUrl!],
                          caption: post.outfit!.name,
                        ),
                        child: ClosyNetworkImage(
                          imageUrl: post.outfit!.coverImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                        ),
                      ),
                      // Badge tên outfit (bấm để mở bài viết chi tiết)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/community/posts/${post.publicId}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.style_outlined, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    post.outfit!.name,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (post.isOutfit && post.outfit != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () => context.push('/community/posts/${post.publicId}'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 120,
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
              ),
            ),

          const SizedBox(height: 6),

          // 5. Actions Footer (Thích, Bình luận, Chia sẻ)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
            child: Row(
              children: [
                // Nút Thích
                InkWell(
                  onTap: () {
                    final authState = ref.read(authStateProvider);
                    if (!authState.isAuthenticated) {
                      requireLogin(context, ref, message: 'Vui lòng đăng nhập để thích bài viết.');
                      return;
                    }
                    onLikeToggle?.call();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: post.isLiked ? const Color(0xFFC85A54) : AppColors.textSecondary,
                          size: 20,
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
                            '${post.likeCount}',
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

                const SizedBox(width: 4),

                // Nút Bình luận
                InkWell(
                  onTap: () {
                    final authState = ref.read(authStateProvider);
                    if (!authState.isAuthenticated) {
                      requireLogin(
                        context,
                        ref,
                        targetRoute: '/community/posts/${post.publicId}?focus=comment',
                        message: 'Vui lòng đăng nhập để bình luận bài viết.',
                      );
                      return;
                    }
                    if (onCommentTap != null) {
                      onCommentTap!();
                    } else {
                      context.push('/community/posts/${post.publicId}?focus=comment');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Nút Chia sẻ
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Chia sẻ liên kết',
                  onPressed: () {
                    ClosyToast.info(context, 'Đã sao chép liên kết: ${post.sharePath}');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
