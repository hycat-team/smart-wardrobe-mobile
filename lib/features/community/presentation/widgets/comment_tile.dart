import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/comment_models.dart';
import 'community_user_avatar.dart';

class CommentTile extends ConsumerWidget {
  final Comment comment;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleReplies;
  final bool isExpanded;
  final bool isLoadingReplies;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onToggleReplies,
    this.isExpanded = false,
    this.isLoadingReplies = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isOwner = comment.isOwnedBy(currentUserId);

    if (comment.isDeleted) {
      return Padding(
        padding: EdgeInsets.only(
          left: isReply ? 46 : 0,
          top: 6,
          bottom: 6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: Text(
                'Bình luận đã bị xóa',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            if (!isReply && comment.replyCount > 0) _buildRepliesToggle(),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 44 : 0,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityUserAvatar(
                user: comment.user,
                size: isReply ? 32 : 38,
                onTap: () {
                  final un = comment.user?.username;
                  if (un != null && un.isNotEmpty) {
                    context.push('/users/$un');
                  }
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isReply ? const Color(0xFFFAF7F2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isReply ? const Color(0xFFEFEBE4) : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              comment.user?.displayName ?? 'Thành viên Closy',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(comment.createdAt),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.primary.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Actions row (Trả lời, Sửa, Xóa)
          Padding(
            padding: EdgeInsets.only(left: isReply ? 42 : 48, top: 4),
            child: Row(
              children: [
                if (!isReply)
                  InkWell(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Trả lời',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentSandDark,
                        ),
                      ),
                    ),
                  ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Chỉnh sửa',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Xóa',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Xem replies toggle (dành cho root comment)
          if (!isReply && comment.replyCount > 0) _buildRepliesToggle(),
        ],
      ),
    );
  }

  Widget _buildRepliesToggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 6),
      child: InkWell(
        onTap: onToggleReplies,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 20, height: 1, color: AppColors.accentSandDark),
              const SizedBox(width: 8),
              if (isLoadingReplies)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                )
              else
                Text(
                  isExpanded
                      ? 'Ẩn phản hồi'
                      : 'Xem ${comment.replyCount} phản hồi',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentSandDark,
                  ),
                ),
            ],
          ),
        ),
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
      if (diff.inMinutes < 60) return '${diff.inMinutes}p';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
