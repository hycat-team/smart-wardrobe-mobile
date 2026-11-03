import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Final onboarding step.
///
/// Style preferences are deliberately **not** collected here: personalization is a membership
/// entitlement, so the style profile lives in its own screen (`/profile/style-profile`) and stays
/// reachable from the Profile tab at any time. Keeping this step free of style pickers keeps signup
/// short and avoids storing a palette the backend cannot use.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  static const List<(IconData, String)> _comingLater = [
    (Icons.palette_outlined, 'Khai gu để gợi ý sát ý bạn hơn'),
    (Icons.block_outlined, 'Chọn phong cách muốn tránh'),
    (Icons.auto_awesome_outlined, 'Xem gợi ý phong cách từ chính tủ đồ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
          onPressed: () => context.go('/wardrobe'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.auto_awesome, size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              Text(
                'Tủ đồ của bạn đã sẵn sàng',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bắt đầu bằng việc thêm vài món đồ yêu thích. Gu phong cách cá nhân là đặc quyền hội viên '
                'và có thể khai bất cứ lúc nào trong mục “Gu của tôi”.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BẠN CÓ THỂ LÀM SAU',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final item in _comingLater)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$1, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.$2,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/wardrobe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  child: Text(
                    'Bắt đầu trải nghiệm',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/wardrobe'),
                  child: Text(
                    'Bỏ qua bước này',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
