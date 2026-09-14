import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ai_quota_display.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key});

  static const Color goldColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(subscriptionOverviewProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Gói Hội Viên & Hạn Mức',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: overviewState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(subscriptionOverviewProvider.notifier).loadOverview();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Current Plan Card
                    _buildCurrentPlanHero(context, overviewState.subscription),
                    const SizedBox(height: 24),

                    // 2. Daily AI Quotas Section (widget dùng chung với Hồ sơ — US4)
                    _buildQuotasSection(
                      overviewState,
                      onRetry: () => ref
                          .read(subscriptionOverviewProvider.notifier)
                          .loadOverview(),
                    ),
                    const SizedBox(height: 28),

                    // 3. Upgrade Banner / Plans Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Các Gói Dịch Vụ',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (!overviewState.subscription.isPremium)
                          GestureDetector(
                            onTap: () => context.push('/profile/subscription/upgrade'),
                            child: const Text(
                              'Nâng cấp ngay →',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    plansAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (_, __) => _buildDefaultPlansList(context, overviewState.subscription),
                      data: (plans) {
                        if (plans.isEmpty) {
                          return _buildDefaultPlansList(context, overviewState.subscription);
                        }
                        return Column(
                          children: plans
                              .map((p) => _buildPlanCard(context, p, overviewState.subscription))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanHero(BuildContext context, UserSubscriptionModel sub) {
    final isPremium = sub.isPremium;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF1E1E1E), const Color(0xFF111111)]
              : [AppColors.surface, AppColors.surfaceSubtle],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? goldColor.withOpacity(0.5) : AppColors.border,
          width: isPremium ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPremium ? 0.12 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium ? goldColor : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPremium ? 'CLOSY VIP' : 'FREE TIER',
                  style: TextStyle(
                    color: isPremium ? Colors.black : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
                color: isPremium ? goldColor : AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sub.planName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isPremium ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Tài khoản Premium thời thượng & đầy đủ đặc quyền'
                : 'Bạn đang sử dụng gói trải nghiệm miễn phí',
            style: TextStyle(
              fontSize: 13,
              color: isPremium ? const Color(0xFFB3B3B3) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x22888888)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'Sức chứa tủ đồ',
                '${sub.maxWardrobeItems} món',
                isPremium: isPremium,
              ),
              _buildMetricItem(
                'Lưu trữ Outfit',
                '${sub.maxOutfits} set',
                isPremium: isPremium,
              ),
              _buildMetricItem(
                'Trạng thái',
                sub.status.toUpperCase() == 'ACTIVE' ? 'Hoạt động' : sub.status,
                isPremium: isPremium,
              ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/profile/subscription/upgrade'),
                icon: const Icon(Icons.flash_on_rounded, size: 18, color: goldColor),
                label: const Text('Nâng cấp lên Premium ngay (59k)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {required bool isPremium}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isPremium ? const Color(0xFF9E9E9E) : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isPremium ? Colors.white : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuotasSection(
    SubscriptionOverviewState overview, {
    VoidCallback? onRetry,
  }) {
    final quota = overview.dailyQuota;
    // Chỉ hiện skeleton/lỗi khi chưa từng có số liệu thật (US4, FR-014).
    final firstLoad = !overview.quotaLoaded;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hạn mức AI hôm nay',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Tự động reset 00:00',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),

          AiQuotaDisplay(
            title: 'Gợi ý phối đồ AI',
            used: quota.aiOutfitUsed,
            limit: quota.aiOutfitLimit,
            icon: Icons.auto_awesome_rounded,
            isLoading: overview.isLoading && firstLoad,
            errorMessage: firstLoad ? overview.errorMessage : null,
            onRetry: onRetry,
            showResetNote: false,
          ),
          const SizedBox(height: 16),

          AiQuotaDisplay(
            title: 'Tư vấn Stylist AI',
            used: quota.aiChatUsed,
            limit: quota.aiChatLimit,
            icon: Icons.chat_bubble_outline_rounded,
            isLoading: overview.isLoading && firstLoad,
            errorMessage: firstLoad ? overview.errorMessage : null,
            onRetry: onRetry,
            showResetNote: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlanModel plan, UserSubscriptionModel currentSub) {
    final isCurrent = plan.slug.toLowerCase() == currentSub.planSlug.toLowerCase();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.8 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang dùng',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.description ?? 'Trải nghiệm phong cách thời trang cùng trợ lý AI thông minh',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedPrice,
                style: GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              if (plan.price > 0)
                const Text(
                  ' / 30 ngày',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () {
                      context.push('/profile/subscription/upgrade');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.surfaceSubtle : AppColors.primary,
                foregroundColor: isCurrent ? AppColors.textSecondary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(isCurrent ? 'Gói hiện tại của bạn' : 'Nâng cấp lên ${plan.name}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlansList(BuildContext context, UserSubscriptionModel currentSub) {
    final defaultPlans = [
      const SubscriptionPlanModel(
        id: 'free',
        name: 'Gói Miễn Phí (Free)',
        slug: 'free',
        price: 0,
        maxWardrobeItems: 100,
        maxOutfits: 100,
        aiOutfitDailyQuota: 5,
        aiChatDailyQuota: 3,
        description: 'Dành cho người mới khám phá tủ đồ số hóa',
        features: [
          'Quản lý tối đa 100 món đồ thời trang',
          'Lưu tối đa 100 set đồ phong cách',
          '5 lượt phối đồ AI tự động / ngày',
          '3 lượt tư vấn Stylist AI / ngày',
        ],
      ),
      const SubscriptionPlanModel(
        id: 'premium-monthly',
        name: 'Gói Cao Cấp (Premium Plan)',
        slug: 'premium-monthly',
        price: 59000,
        maxWardrobeItems: 300,
        maxOutfits: 300,
        aiOutfitDailyQuota: 15,
        aiChatDailyQuota: 20,
        description: 'Trải nghiệm không giới hạn cùng trợ lý thời trang cá nhân AI',
        features: [
          'Quản lý đến 300 món đồ thời trang',
          'Lưu trữ đến 300 set trang phục phong cách',
          '15 lượt gợi ý phối đồ AI thông minh / ngày',
          '20 lượt trò chuyện Stylist AI riêng biệt / ngày',
          'Trải nghiệm không quảng cáo & ưu tiên xử lý AI',
          'Đồng bộ hóa đám mây đa thiết bị tức thì',
        ],
      ),
    ];

    return Column(
      children: defaultPlans.map((p) => _buildPlanCard(context, p, currentSub)).toList(),
    );
  }
}
