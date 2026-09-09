import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _handlePickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải ảnh đại diện lên Cloudinary...'),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await ref.read(userProfileProvider.notifier).uploadAvatar(picked);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        final error = ref.read(userProfileProvider).errorMessage ?? 'Không thể tải ảnh đại diện';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất tài khoản',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này trên thiết bị không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final subOverview = ref.watch(subscriptionOverviewProvider);
    final bodyProfileState = ref.watch(bodyProfileProvider);

    final user = userProfileState.user ?? authState.user;
    final isAuth = authState.isAuthenticated;
    final bodyProfile = bodyProfileState.profile;

    final sub = subOverview.subscription;
    final quota = subOverview.dailyQuota;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hồ sơ cá nhân',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (isAuth)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới',
              onPressed: () {
                ref.read(userProfileProvider.notifier).loadUserProfile();
                ref.read(subscriptionOverviewProvider.notifier).loadOverview();
                ref.read(bodyProfileProvider.notifier).loadProfile();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Header Profile & Avatar
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.accentSand.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: ClipOval(
                        child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                            ? ClosyNetworkImage(
                                imageUrl: user.avatarUrl!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  (user?.fullName ?? user?.username ?? 'U')
                                      .trim()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isAuth)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: userProfileState.isUpdating ? null : _handlePickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: userProfileState.isUpdating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        isAuth
                            ? (user?.fullName ?? user?.username ?? 'Thành viên Closy')
                            : 'Khách khám phá',
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAuth && sub.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAuth
                      ? (user?.email ?? '')
                      : 'Đăng nhập để đồng bộ tủ đồ của bạn trên mọi thiết bị',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Quick Body Stats Pill
                if (isAuth && bodyProfile.heightCm > 0)
                  GestureDetector(
                    onTap: () => context.push('/profile/body'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.accessibility_new_rounded,
                              size: 14, color: AppColors.accentSandDark),
                          const SizedBox(width: 6),
                          Text(
                            '${bodyProfile.heightCm.toInt()} cm • ${bodyProfile.weightKg.toInt()} kg • ${bodyProfile.bodyShapeTitle}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                if (!isAuth) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Subscription & Daily AI Quota Card
          if (isAuth) ...[
            _buildSubscriptionCard(sub, quota),
            const SizedBox(height: 20),
          ],

          // 3. Menu Navigation List
          _buildMenuSection(isAuth),
          const SizedBox(height: 24),

          // 4. Logout Button
          if (isAuth)
            OutlinedButton.icon(
              onPressed: _showLogoutConfirmDialog,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserSubscriptionModel sub, DailyQuotaModel quota) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sub.isPremium ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                      color: AppColors.accentSand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.planName.toUpperCase(),
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        sub.expiresAt != null && sub.expiresAt!.isNotEmpty
                            ? 'Hạn dùng: ${sub.expiresAt!.substring(0, 10)}'
                            : 'Gói tiêu chuẩn mặc định',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/profile/subscription'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentSand,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 0.6,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 14),

          // Daily AI Quota Progress
          Text(
            'HẠN MỨC SỬ DỤNG AI HÔM NAY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.accentSand.withOpacity(0.9),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Quota 1: AI Outfit
          _buildQuotaRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Gợi ý phối đồ AI',
            used: quota.aiOutfitUsed,
            limit: quota.aiOutfitLimit,
            progress: quota.outfitProgress,
          ),
          const SizedBox(height: 10),

          // Quota 2: Stylist Chat AI
          _buildQuotaRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Tư vấn Stylist AI',
            used: quota.aiChatUsed,
            limit: quota.aiChatLimit,
            progress: quota.chatProgress,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaRow({
    required IconData icon,
    required String title,
    required int used,
    required int limit,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
            Text(
              '$used / $limit lượt',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.9 ? Colors.orange.shade300 : AppColors.accentSand,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(bool isAuth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TÀI KHOẢN & HỆ THỐNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ),
        _buildMenuTile(
          Icons.person_outline_rounded,
          'Chỉnh sửa thông tin cá nhân',
          'Cập nhật họ tên, ngày sinh, giới tính và địa chỉ',
          () => context.push('/profile/edit'),
        ),
        _buildMenuTile(
          Icons.lock_outline_rounded,
          'Bảo mật & Đổi mật khẩu',
          'Đổi mật khẩu tài khoản và quản lý đăng xuất',
          () => context.push('/profile/change-password'),
        ),
        _buildMenuTile(
          Icons.workspace_premium_outlined,
          'Gói hội viên & Hạn mức AI',
          'Xem quyền lợi chi tiết và các gói dịch vụ nâng cấp',
          () => context.push('/profile/subscription'),
        ),
        _buildMenuTile(
          Icons.accessibility_new_rounded,
          'Hồ sơ số đo & Dáng người',
          'Cập nhật chiều cao, cân nặng, dáng người và số đo 3 vòng',
          () => context.push('/profile/body'),
        ),
        _buildMenuTile(
          Icons.analytics_outlined,
          'Thống kê & Phân tích tủ đồ',
          'Xem giá trị tủ đồ, tỷ lệ danh mục và các món đồ ít mặc',
          () => context.push('/wardrobe/insights'),
        ),
        _buildMenuTile(
          Icons.favorite_outline_rounded,
          'Yêu thích & Outfits đã lưu',
          'Danh sách các set đồ thời trang yêu thích của bạn',
          () => context.push('/outfits'),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.6),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
