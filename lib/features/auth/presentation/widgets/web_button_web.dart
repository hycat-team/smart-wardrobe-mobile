import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import '../../../../core/theme/app_theme.dart';
import 'google_logo.dart';

/// Web dùng **Google Identity Services (GIS)** để lấy ID token → gửi
/// `POST /auth/google` → nhận Bearer token (giống mobile).
///
/// LƯU Ý: GIS bắt buộc origin của trang web phải nằm trong
/// **Authorized JavaScript origins** của OAuth client trên Google Cloud,
/// nếu thiếu sẽ gặp lỗi `400: origin_mismatch`.
Widget buildWebGoogleButton({VoidCallback? onDisabledTap, double? width}) {
  final platform = GoogleSignInPlatform.instance;
  if (platform is GoogleSignInPlugin) {
    // Đặt minimumWidth = bề rộng khung để nút Google render vừa khung
    // (tránh bị cắt 2 mép khi nhãn tiếng Việt dài).
    final minWidth = (width != null && width.isFinite && width > 0
            ? width
            : 320.0)
        .clamp(200.0, 600.0)
        .toDouble();
    return platform.renderButton(
      configuration: GSIButtonConfiguration(
        type: GSIButtonType.standard,
        theme: GSIButtonTheme.outline,
        size: GSIButtonSize.large,
        shape: GSIButtonShape.pill,
        text: GSIButtonText.continueWith,
        minimumWidth: minWidth,
      ),
    );
  }

  // Fallback (không dùng được GIS): nút Quiet Luxury full width.
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton(
      onPressed: onDisabledTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFFE5E2DE), width: 1.0),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const GoogleLogo(size: 20),
          const SizedBox(width: 12),
          Text(
            'Tiếp tục với Google',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
