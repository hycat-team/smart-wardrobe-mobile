import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../../outfit_studio/providers/outfits_list_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../wardrobe/models/wardrobe_models.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

/// Trang Home theo phong cách Quiet Luxury của Closy
/// Hiển thị lời chào cá nhân hóa, card gợi ý AI Stylist,
/// thống kê nhanh tủ đồ & outfits, và danh mục phân loại trang phục.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).user;
    // Số liệu tổng quan lấy từ cùng nguồn API với trang Thống kê tủ đồ
    // (US 006) — không đếm từ list phân trang.
    final insightsAsync = ref.watch(wardrobeInsightsProvider);
    final statsAsync = ref.watch(wardrobeStatsProvider);
    final distributionAsync = ref.watch(categoryDistributionProvider);

    // Lấy tên hiển thị chào mừng
    final greetingName = _resolveGreetingName(userProfile?.firstName, userProfile?.displayName);
    final initials = _resolveInitials(userProfile?.firstName, userProfile?.lastName, userProfile?.displayName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(wardrobeProvider);
            ref.invalidate(outfitsListProvider);
            ref.invalidate(categoryDistributionProvider);
            ref.invalidate(wardrobeInsightsProvider);
            ref.invalidate(wardrobeStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 1. Header Chào mừng & Avatar
                _buildHeader(context, greetingName: greetingName, initials: initials, avatarUrl: userProfile?.avatarUrl),

                const SizedBox(height: 22),

                // 2. AI Stylist Hero Recommendation Banner
                _buildAiStylistHeroCard(context),

                const SizedBox(height: 18),

                // 3. Quick Stats Row (cùng nguồn API với trang Thống kê)
                _buildQuickStatsRow(
                  context,
                  ref,
                  wardrobeCount: insightsAsync.whenData((i) => i.totalItems),
                  outfitCount: statsAsync.whenData((s) => s.outfitsCount),
                ),

                const SizedBox(height: 28),

                // 4. Mục "TỦ ĐỒ CỦA BẠN" với các thẻ danh mục
                _buildWardrobeCategoriesSection(context, ref, distributionAsync),

                // Khoảng đệm an toàn dưới cùng để không bị che bởi BottomNavBar (76px)
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Trích xuất tên ngắn gọn để chào hỏi (Ví dụ "Mai Anh")
  String _resolveGreetingName(String? firstName, String? displayName) {
    if (firstName != null && firstName.trim().isNotEmpty) {
      return firstName.trim();
    }
    if (displayName != null && displayName.trim().isNotEmpty && displayName != 'Người dùng Closy') {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]} ${parts.last}';
      }
      return parts.last;
    }
    return 'Mai Anh';
  }

  /// Tạo chữ viết tắt 2 ký tự đại diện cho avatar khi chưa có ảnh (Ví dụ "MA")
  String _resolveInitials(String? firstName, String? lastName, String? displayName) {
    if (firstName != null && firstName.trim().isNotEmpty) {
      final fn = firstName.trim();
      final ln = lastName?.trim() ?? '';
      if (ln.isNotEmpty) {
        return '${fn[0]}${ln[0]}'.toUpperCase();
      }
      return fn.substring(0, fn.length >= 2 ? 2 : 1).toUpperCase();
    }
    if (displayName != null && displayName.trim().isNotEmpty && displayName != 'Người dùng Closy') {
      final words = displayName.trim().split(RegExp(r'\s+'));
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'MA';
  }

  /// Header gồm lời chào & avatar tròn
  Widget _buildHeader(
    BuildContext context, {
    required String greetingName,
    required String initials,
    String? avatarUrl,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BỘ SƯU TẬP HÔM NAY',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Xin chào, $greetingName',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('✨', style: TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Avatar circle
        InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1EFEA),
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClosyNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                  )
                : Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Banner gợi ý AI Stylist tông đen sang trọng (Dark Luxury Card)
  Widget _buildAiStylistHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B18),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'AI Stylist gợi ý',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE2D5C8),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tiêu đề gợi ý phong cách
            Text(
              'Phong cách Parisian Minimalist',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Mô tả chi tiết cách phối
            Text(
              'Phối hợp áo trench coat cùng quần ống suông tôn dáng.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.72),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // Nút "Khám phá ngay >" màu caramel/sand
            InkWell(
              onTap: () => context.go('/studio'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFBE9B7B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Khám phá ngay',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1B18),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF1E1B18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2 Thẻ thống kê: Tủ đồ hiện có (món) & Outfits đã lưu (set).
  /// Số liệu từ cùng nguồn API với trang Thống kê (US 006).
  Widget _buildQuickStatsRow(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<int> wardrobeCount,
    required AsyncValue<int> outfitCount,
  }) {
    return Row(
      children: [
        // Thẻ 1: Tủ đồ hiện có
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Tủ đồ hiện có',
            countAsync: wardrobeCount,
            unit: 'món',
            onTap: () => context.go('/wardrobe'),
            onRetry: () => ref.invalidate(wardrobeInsightsProvider),
          ),
        ),
        const SizedBox(width: 14),

        // Thẻ 2: Outfits đã lưu
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Outfits đã lưu',
            countAsync: outfitCount,
            unit: 'set',
            onTap: () => context.push('/outfits'),
            onRetry: () => ref.invalidate(wardrobeStatsProvider),
          ),
        ),
      ],
    );
  }

  /// Thẻ metric tối giản phong cách Quiet Luxury.
  /// Chưa có số liệu thì hiện chờ/lỗi + thử lại, không hiện số thiếu (US 006).
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required AsyncValue<int> countAsync,
    required String unit,
    required VoidCallback onTap,
    VoidCallback? onRetry,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            countAsync.when(
              data: (count) => RichText(
                text: TextSpan(
                  text: '$count ',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: unit,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (_, __) => InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Thử lại',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mục "TỦ ĐỒ CỦA BẠN" với các card danh mục trang phục
  Widget _buildWardrobeCategoriesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<WardrobeCategoryDistributionResult> distributionAsync,
  ) {
    // Trích xuất số lượng theo danh mục từ API nếu có
    int coatCount = 8;
    int dressCount = 12;
    int accessoryCount = 15;

    distributionAsync.whenData((dist) {
      for (final cat in dist.categories) {
        final nameLower = cat.categoryName.toLowerCase();
        if (nameLower.contains('khoác') || nameLower.contains('coat') || nameLower.contains('jacket')) {
          coatCount = cat.itemCount;
        } else if (nameLower.contains('đầm') || nameLower.contains('váy') || nameLower.contains('dress')) {
          dressCount = cat.itemCount;
        } else if (nameLower.contains('phụ kiện') || nameLower.contains('accessory') || nameLower.contains('giày')) {
          accessoryCount = cat.itemCount;
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mục
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'TỦ ĐỒ CỦA BẠN',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            InkWell(
              onTap: () => context.go('/wardrobe'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3 Cards danh mục: Áo khoác, Đầm & Váy, Phụ kiện
        Row(
          children: [
            // 1. Áo khoác
            Expanded(
              child: _CategoryItemCard(
                title: 'Áo khoác',
                countText: '$coatCount món',
                icon: Icons.layers_outlined,
                iconColor: const Color(0xFFC29B38),
                badgeBgColor: const Color(0xFFFBF6EC),
                onTap: () => _navigateToWardrobeCategory(context, ref, 'ao-khoac'),
              ),
            ),
            const SizedBox(width: 10),

            // 2. Đầm & Váy
            Expanded(
              child: _CategoryItemCard(
                title: 'Đầm & Váy',
                countText: '$dressCount món',
                icon: Icons.checkroom_rounded,
                iconColor: const Color(0xFF3B82F6),
                badgeBgColor: const Color(0xFFEFF6FF),
                onTap: () => _navigateToWardrobeCategory(context, ref, 'dam-vay'),
              ),
            ),
            const SizedBox(width: 10),

            // 3. Phụ kiện
            Expanded(
              child: _CategoryItemCard(
                title: 'Phụ kiện',
                countText: '$accessoryCount món',
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFFE11D48),
                badgeBgColor: const Color(0xFFFFF1F2),
                onTap: () => _navigateToWardrobeCategory(context, ref, 'phu-kien'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Lọc danh mục trong wardrobe rồi điều hướng sang tab /wardrobe
  void _navigateToWardrobeCategory(BuildContext context, WidgetRef ref, String categorySlug) {
    ref.read(selectedCategorySlugProvider.notifier).state = categorySlug;
    context.go('/wardrobe');
  }
}

/// Thẻ hiển thị một danh mục trang phục (Icon hình tượng, Tên, Số lượng)
class _CategoryItemCard extends StatelessWidget {
  const _CategoryItemCard({
    required this.title,
    required this.countText,
    required this.icon,
    required this.iconColor,
    required this.badgeBgColor,
    required this.onTap,
  });

  final String title;
  final String countText;
  final IconData icon;
  final Color iconColor;
  final Color badgeBgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.6),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            // Icon container với nền pastel tinh tế
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tên danh mục
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 3),

            // Số lượng món
            Text(
              countText,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
