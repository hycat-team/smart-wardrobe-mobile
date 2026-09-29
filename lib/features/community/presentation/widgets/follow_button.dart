import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/community_error.dart';

class FollowButton extends ConsumerWidget {
  final String username;
  final bool isFollowing;
  final bool isMe;
  final VoidCallback? onToggleFollow;
  final bool isCompact;

  const FollowButton({
    super.key,
    required this.username,
    required this.isFollowing,
    this.isMe = false,
    this.onToggleFollow,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ẩn nút theo dõi với chính mình (FR-015)
    if (isMe) {
      return const SizedBox.shrink();
    }

    void handleTap() {
      final authState = ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        requireLogin(
          context,
          ref,
          message: 'Vui lòng đăng nhập để theo dõi người dùng này.',
        );
        return;
      }
      onToggleFollow?.call();
    }

    if (isFollowing) {
      return OutlinedButton(
        onPressed: handleTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.0),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 18,
            vertical: isCompact ? 6 : 10,
          ),
          minimumSize: Size(isCompact ? 90 : 110, isCompact ? 34 : 42),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: AppColors.accentSandDark),
            const SizedBox(width: 4),
            Text(
              'Đang theo dõi',
              style: GoogleFonts.beVietnamPro(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 20,
          vertical: isCompact ? 6 : 10,
        ),
        minimumSize: Size(isCompact ? 80 : 100, isCompact ? 34 : 42),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Theo dõi',
            style: GoogleFonts.beVietnamPro(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
