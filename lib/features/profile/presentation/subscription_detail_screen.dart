import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  static const Color goldColor = Color(0xFFD4AF37);

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen>
    with WidgetsBindingObserver {
  Color get goldColor => SubscriptionDetailScreen.goldColor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Tải lại ngay khi mở màn hình để phản ánh kết quả thanh toán web.
    Future.microtask(() => _reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tự động đồng bộ gói khi quay lại app sau khi thanh toán trên web.
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  void _reload() {
    if (!mounted) return;
    ref.read(subscriptionOverviewProvider.notifier).loadOverview();
    ref.invalidate(subscriptionPlansProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildUsageSection(overviewState),
                    const SizedBox(height: 28),

                    // 3. Upgrade Banner / Plans Section
                    Text(
                      'Các Gói Dịch Vụ',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.language_rounded, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Thực hiện nâng cấp gói trên web',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
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
                  isPremium ? 'CLOSY VIP' : 'GÓI MIỄN PHÍ',
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Tài khoản Premium thời thượng & đầy đủ đặc quyền'
                : 'Bạn đang sử dụng gói trải nghiệm miễn phí',
            style: const TextStyle(fontSize: 13, color: Color(0xFFB3B3B3)),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x22888888)),
          const SizedBox(height: 14),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cá nhân hoá gu',
                style: const TextStyle(fontSize: 13, color: Color(0xFFB3B3B3)),
              ),
              Row(
                children: [
                  Icon(
                    sub.personalizationEnabled
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: sub.personalizationEnabled ? AppColors.accentSand : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sub.personalizationEnabled ? 'Đã bật' : 'Chưa có',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(SubscriptionOverviewState overview) {
    final sub = overview.subscription;
    final quota = overview.dailyQuota;
    final stats = overview.wardrobeStats;
    final statsReady = overview.statsLoaded;
    final quotaReady = overview.quotaLoaded;

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
          Text(
            'HẠN MỨC & SỬ DỤNG',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _QuotaRow(
            icon: Icons.layers_outlined,
            label: 'Sức chứa tủ đồ',
            used: statsReady ? stats.activeItemsCount : null,
            max: sub.maxWardrobeItems,
          ),
          const SizedBox(height: 14),
          _QuotaRow(
            icon: Icons.checkroom_outlined,
            label: 'Bộ phối đồ',
            used: statsReady ? stats.outfitsCount : null,
            max: sub.maxOutfits,
          ),
          const SizedBox(height: 14),
          _QuotaRow(
            icon: Icons.auto_awesome_outlined,
            label: 'Tạo phối đồ AI (ngày)',
            used: quotaReady ? quota.aiOutfitUsed : null,
            max: quota.aiOutfitLimit,
          ),
          const SizedBox(height: 14),
          _QuotaRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat với AI (ngày)',
            used: quotaReady ? quota.aiChatUsed : null,
            max: quota.aiChatLimit,
          ),
          if (overview.statsError != null && !statsReady) ...[
            const SizedBox(height: 12),
            Text(
              'Không tải được số liệu tủ đồ.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
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
          ..._buildPlanBenefits(plan).map(
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
        ],
      ),
    );
  }

  /// Entitlements rendered exactly like the web pricing card so both surfaces agree.
  List<String> _buildPlanBenefits(SubscriptionPlanModel plan) {
    return [
      'Tối đa ${plan.maxWardrobeItems} món đồ trong tủ',
      'Tối đa ${plan.maxOutfits} bộ phối',
      'Tạo phối đồ AI: ${plan.aiOutfitDailyQuota} lần/ngày',
      'Chat với AI: ${plan.aiChatDailyQuota} lần/ngày',
      if (plan.personalizationEnabled) 'Cá nhân hoá gu',
      ...plan.features,
    ];
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

/// One "used / max" line with a hairline progress bar, matching the web `CurrentPlanCard`.
class _QuotaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// null when the value has not been loaded yet — renders "—" instead of a fake 0.
  final int? used;
  final int max;

  const _QuotaRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = max <= 0;
    final usedValue = used ?? 0;
    final text = used == null
        ? '—'
        : (isUnlimited ? '$usedValue / ∞' : '$usedValue / $max');
    final progress =
        (used == null || isUnlimited || max <= 0) ? 0.0 : (usedValue / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentSand),
          ),
        ),
      ],
    );
  }
}
