import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Màn hình khởi động (spec 015 — Nhóm A).
///
/// Hiện ở **mọi** lần khởi động ứng dụng (FR-003) và **ở lại** khi kiểm tra phiên
/// gặp lỗi tạm thời (FR-027) — lúc đó hiện thông báo tiếng Việt cùng nút "Thử lại".
/// Tự ẩn sau tối đa 1 giây nếu việc kiểm tra hoàn tất sớm (FR-005).
class SplashScreen extends StatelessWidget {
  /// Thông báo lỗi tạm thời. `null` = đang kiểm tra bình thường.
  final String? errorMessage;

  /// Bấm "Thử lại". `null` = không cho thử lại (đang kiểm tra).
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  bool get _isWaitingRetry => errorMessage != null && onRetry != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 44,
                  color: AppColors.accentSandDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Closy',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              if (_isWaitingRetry) ...[
                // Lỗi tạm thời: dừng spinner, đưa ra thông báo + hành động.
                Icon(
                  Icons.wifi_off_rounded,
                  size: 32,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(height: 14),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  // Vùng chạm >= 44px (AGENTS.md §5).
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border, width: 1),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                    ),
                  ),
                ),
              ] else
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accentSandDark),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
