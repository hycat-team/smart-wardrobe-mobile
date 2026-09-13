import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';
import '../utils/payment_link_opener.dart';
import 'widgets/topup_bottom_sheet.dart';

class SubscriptionUpgradeScreen extends ConsumerStatefulWidget {
  const SubscriptionUpgradeScreen({super.key});

  @override
  ConsumerState<SubscriptionUpgradeScreen> createState() => _SubscriptionUpgradeScreenState();
}

class _SubscriptionUpgradeScreenState extends ConsumerState<SubscriptionUpgradeScreen> {
  bool _isProcessing = false;

  Future<void> _handleUpgrade(SubscriptionPlanModel premiumPlan) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(subscriptionOverviewProvider.notifier);
      final urls = PaymentReturnUrls.forPurchase(
        isWeb: kIsWeb,
        webOrigin: kIsWeb ? Uri.base.origin : null,
        amount: premiumPlan.price.toDouble(),
      );
      final link = await notifier.createPurchase(
        premiumPlan.slug.isNotEmpty ? premiumPlan.slug : 'premium-monthly',
        returnUrl: urls.returnUrl,
        cancelUrl: urls.cancelUrl,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (link != null && link.paymentUrl.isNotEmpty) {
        final pending = PendingPayment.purchase(
          link: link,
          amount: premiumPlan.price.toDouble(),
          planLabel: '${premiumPlan.name} (${premiumPlan.durationDays} ngày)',
        );
        // 1. Open PayOS Checkout URL
        await openPaymentLink(
          context,
          paymentUrl: pending.paymentUrl,
          orderCode: pending.orderCode,
        );

        // 2. Navigate to waiting screen with live polling
        if (mounted) {
          context.push('/profile/subscription/waiting', extra: pending);
        }
      } else {
        final err = ref.read(subscriptionOverviewProvider).purchaseErrorMessage ??
            'Không thể tạo link thanh toán PayOS. Vui lòng thử lại!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }


  Future<void> _handlePurchaseWithWallet(SubscriptionPlanModel plan) async {
    final walletState = ref.read(walletProvider);
    final wallet = walletState.wallet;

    if (wallet.balance < plan.price) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const TopUpBottomSheet(),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Bạn có chắc muốn dùng ${plan.formattedPrice} từ Ví Closy để đăng ký ${plan.name} không?\n\nSố dư ví hiện tại: ${wallet.formattedBalance}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF1E242B),
            ),
            child: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final notifier = ref.read(subscriptionOverviewProvider.notifier);
    final success = await notifier.purchaseWithWallet(plan.slug.isNotEmpty ? plan.slug : 'premium-monthly');

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ref.read(walletProvider.notifier).loadWallet();

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFFD4AF37)),
          title: const Text('Nâng Cấp Thành Công!'),
          content: const Text('Tài khoản của bạn đã được nâng cấp lên Closy Premium. Tận hưởng các đặc quyền AI ngay bây giờ!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tuyệt vời'),
            ),
          ],
        ),
      );
    } else {
      final err = ref.read(subscriptionOverviewProvider).purchaseErrorMessage ?? 'Thanh toán bằng ví thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(subscriptionOverviewProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    final currentSub = overviewState.subscription;
    final isAlreadyPremium = currentSub.isPremium;

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
          'Gói Hội Viên Closy',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: plansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => _buildUpgradeContent(
          context,
          freePlan: const SubscriptionPlanModel(
            id: 'free',
            name: 'Miễn Phí',
            slug: 'free',
            price: 0,
            maxWardrobeItems: 100,
            maxOutfits: 100,
            aiOutfitDailyQuota: 5,
            aiChatDailyQuota: 3,
          ),
          premiumPlan: const SubscriptionPlanModel(
            id: 'premium-monthly',
            name: 'Premium Plan',
            slug: 'premium-monthly',
            price: 59000,
            maxWardrobeItems: 300,
            maxOutfits: 300,
            aiOutfitDailyQuota: 15,
            aiChatDailyQuota: 20,
          ),
          isAlreadyPremium: isAlreadyPremium,
        ),
        data: (plans) {
          SubscriptionPlanModel freePlan = const SubscriptionPlanModel(
            id: 'free',
            name: 'Miễn Phí',
            slug: 'free',
            price: 0,
            maxWardrobeItems: 100,
            maxOutfits: 100,
            aiOutfitDailyQuota: 5,
            aiChatDailyQuota: 3,
          );
          SubscriptionPlanModel premiumPlan = const SubscriptionPlanModel(
            id: 'premium-monthly',
            name: 'Premium Plan',
            slug: 'premium-monthly',
            price: 59000,
            maxWardrobeItems: 300,
            maxOutfits: 300,
            aiOutfitDailyQuota: 15,
            aiChatDailyQuota: 20,
          );

          for (final p in plans) {
            if (p.slug.toLowerCase().contains('premium') || p.price > 0) {
              premiumPlan = p;
            } else {
              freePlan = p;
            }
          }

          return _buildUpgradeContent(
            context,
            freePlan: freePlan,
            premiumPlan: premiumPlan,
            isAlreadyPremium: isAlreadyPremium,
          );
        },
      ),
    );
  }

  Widget _buildUpgradeContent(
    BuildContext context, {
    required SubscriptionPlanModel freePlan,
    required SubscriptionPlanModel premiumPlan,
    required bool isAlreadyPremium,
  }) {
    const goldColor = Color(0xFFD4AF37);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Hero
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: goldColor.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 18, color: goldColor),
                  SizedBox(width: 6),
                  Text(
                    'CLOSY LUXURY VIP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nâng Tầm Tủ Đồ Của Bạn',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khai mở tối đa sức mạnh Stylist AI cá nhân & mở rộng không gian lưu trữ tủ đồ phong cách thời thượng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Pricing Feature Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                        color: goldColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PHỔ BIẾN NHẤT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Icon(Icons.stars_rounded, color: goldColor, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  premiumPlan.name,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toàn quyền truy cập trợ lý Stylist AI thông minh mỗi ngày',
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      premiumPlan.formattedPrice,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '/ 30 ngày',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF2E2E2E), height: 1),
                const SizedBox(height: 18),

                // Key bullet points
                ...premiumPlan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: goldColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Color(0xFFEEEEEE),
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Comparison Table: Free vs Premium
          Text(
            'So sánh đặc quyền',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildComparisonHeader(),
                const Divider(height: 1, color: AppColors.border),
                _buildComparisonRow('Sức chứa tủ đồ', '${freePlan.maxWardrobeItems} món', '${premiumPlan.maxWardrobeItems} món', isHighlight: true),
                const Divider(height: 1, color: AppColors.divider),
                _buildComparisonRow('Lưu trữ Outfit', '${freePlan.maxOutfits} set', '${premiumPlan.maxOutfits} set', isHighlight: true),
                const Divider(height: 1, color: AppColors.divider),
                _buildComparisonRow('Phối đồ AI tự động', '${freePlan.aiOutfitDailyQuota} lượt/ngày', '${premiumPlan.aiOutfitDailyQuota} lượt/ngày', isHighlight: true),
                const Divider(height: 1, color: AppColors.divider),
                _buildComparisonRow('Trò chuyện AI Stylist', '${freePlan.aiChatDailyQuota} lượt/ngày', '${premiumPlan.aiChatDailyQuota} lượt/ngày', isHighlight: true),
                // const Divider(height: 1, color: AppColors.divider),
                // _buildComparisonRow('Ưu tiên xử lý AI', 'Bình thường', 'Tốc độ cao ⚡', isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Security & Guarantee Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.green, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thanh toán an toàn qua VietQR / PayOS',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hỗ trợ 40+ ngân hàng Việt Nam, quét QR banking nhanh chóng & kích hoạt tài khoản tức thì.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Upgrade CTA Button
          if (isAlreadyPremium)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Bạn đang sử dụng gói Premium',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          else
            Consumer(
              builder: (context, ref, _) {
                final wallet = ref.watch(walletProvider).wallet;
                final hasEnough = wallet.balance >= premiumPlan.price;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wallet Balance Card Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: (hasEnough ? goldColor : Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (hasEnough ? goldColor : Colors.grey).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 18,
                                color: hasEnough ? goldColor : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Số dư Ví Closy:',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            wallet.formattedBalance,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: hasEnough ? goldColor : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Option 1: Purchase with Wallet
                    ElevatedButton(
                      onPressed: _isProcessing ? null : () => _handlePurchaseWithWallet(premiumPlan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasEnough ? goldColor : const Color(0xFF2C3440),
                        foregroundColor: hasEnough ? const Color(0xFF1E242B) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: hasEnough ? 2 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasEnough ? Icons.flash_on_rounded : Icons.add_circle_outline_rounded,
                            size: 20,
                            color: hasEnough ? const Color(0xFF1E242B) : goldColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasEnough
                                ? 'Mua Bằng Ví Closy (${premiumPlan.formattedPrice})'
                                : 'Ví Không Đủ Tiền • Nạp Thêm Ngay',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Option 2: PayOS Direct
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleUpgrade(premiumPlan),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: const Text(
                        'Quét VietQR Trực Tiếp (PayOS)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('Tính năng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String freeValue, String premiumValue, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              premiumValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
