import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import 'google_logo.dart';

/// Bắt đầu đăng nhập Google trên **Web** qua luồng redirect của BE (guide §1):
/// trình duyệt rời app sang Google → BE đặt cookie HttpOnly → quay về
/// `/auth/callback`. Luồng này KHÔNG cần "Authorized JavaScript origins" (khác
/// GIS) nên tránh được lỗi `400: origin_mismatch`.
void startWebGoogleRedirect() {
  final returnUrl = '${Uri.base.origin}/auth/callback';
  web.window.location.href = AppConstants.googleWebRedirectUrl(returnUrl);
}

/// Nút "Tiếp tục với Google" phong cách Quiet Luxury cho Web.
Widget buildWebGoogleButton({VoidCallback? onDisabledTap}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton(
      onPressed: onDisabledTap ?? startWebGoogleRedirect,
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
