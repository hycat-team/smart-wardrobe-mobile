import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/closy_network_image.dart';
import '../../models/community_user.dart';

class CommunityUserAvatar extends StatelessWidget {
  final CommunityUser? user;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;

  const CommunityUserAvatar({
    super.key,
    this.user,
    this.size = 40,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl;
    final initials = user?.initials ?? 'CL';

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF3EFEA),
        border: showBorder
            ? Border.all(
                color: AppColors.border,
                width: 1.0,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClosyNetworkImage(
              imageUrl: avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Center(
              child: Text(
                initials,
                style: GoogleFonts.beVietnamPro(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: avatarWidget,
        ),
      );
    }

    return avatarWidget;
  }
}
