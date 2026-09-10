import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class PaymentWaitingScreen extends ConsumerStatefulWidget {
  final PaymentLinkModel paymentLink;

  const PaymentWaitingScreen({super.key, required this.paymentLink});

  @override
  ConsumerState<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends ConsumerState<PaymentWaitingScreen> with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;
  int _secondsElapsed = 0;
  bool _isSuccess = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      setState(() => _secondsElapsed += 3);

      final notifier = ref.read(subscriptionOverviewProvider.notifier);
      final isPremiumNow = await notifier.checkSubscriptionStatus();

      if (isPremiumNow && mounted) {
        timer.cancel();
        setState(() => _isSuccess = true);
      }

      // If waiting more than 15 minutes (900s), cancel timer
      if (_secondsElapsed >= 900) {
        timer.cancel();
      }
    });
  }

  Future<void> _reopenPayOS() async {
    final uri = Uri.parse(widget.paymentLink.paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessCelebration();
    }

    const goldColor = Color(0xFFD4AF37);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Rời khỏi trang thanh toán?'),
            content: const Text(
              'Giao dịch của bạn vẫn đang được hệ thống xử lý. Bạn có thể quay lại trang hội viên để xem trạng thái bất cứ lúc nào.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Ở lại'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rời khỏi'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Thanh Toán PayOS',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          elevation: 0,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Animated hourglass / pulse icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: goldColor.withOpacity(0.4 + (_pulseController.value * 0.4)),
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          size: 42,
                          color: goldColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Đang Chờ Thanh Toán...',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng hoàn tất thanh toán trên cổng PayOS hoặc ứng dụng ngân hàng của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Order detail card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Mã đơn hàng', '#${widget.paymentLink.orderCode}', isBold: true),
                    const Divider(height: 24),
                    _buildInfoRow('Số tiền', '249.000 đ', isBold: true),
                    const Divider(height: 24),
                    _buildInfoRow('Gói đăng ký', 'Premium (30 ngày)'),
                    const Divider(height: 24),
                    _buildInfoRow('Phương thức', 'VietQR / Banking'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live auto-reconcile status box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: goldColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tự động kiểm tra giao dịch',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đang lắng nghe xác nhận từ ngân hàng (${_formatElapsed(_secondsElapsed)})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Button: Reopen PayOS
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _reopenPayOS,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    'Mở lại trang thanh toán PayOS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note
              const Text(
                'Hệ thống tự động kiểm tra mỗi 3 giây. Ngay khi giao dịch được xác nhận, tài khoản của bạn sẽ lập tức được nâng cấp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFFD4AF37) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCelebration() {
    const goldColor = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 60,
                    color: goldColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Chúc Mừng Bạn!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài khoản của bạn đã được nâng cấp thành công lên Closy Premium.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Unlocked perks card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: goldColor.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildPerkItem(Icons.checkroom_rounded, '300 món đồ trong tủ cá nhân'),
                    const SizedBox(height: 12),
                    _buildPerkItem(Icons.auto_awesome_rounded, '15 lượt phối đồ AI tự động mỗi ngày'),
                    const SizedBox(height: 12),
                    _buildPerkItem(Icons.chat_bubble_outline_rounded, '20 lượt tư vấn Stylist AI mỗi ngày'),
                    const SizedBox(height: 12),
                    _buildPerkItem(Icons.speed_rounded, 'Xử lý ưu tiên không giới hạn'),
                  ],
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Refresh overview and back to profile
                    ref.read(subscriptionOverviewProvider.notifier).loadOverview();
                    context.go('/profile/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Khám Phá Đặc Quyền Ngay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkItem(IconData icon, String text) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: goldColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
