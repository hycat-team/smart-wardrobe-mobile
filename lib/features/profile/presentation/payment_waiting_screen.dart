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
  bool _isCheckingManually = false;
  bool _isSimulating = false;
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

      // If waiting more than 10 minutes (600s), cancel timer
      if (_secondsElapsed >= 600) {
        timer.cancel();
      }
    });
  }

  Future<void> _manualCheck() async {
    if (_isCheckingManually || _isSuccess) return;
    setState(() => _isCheckingManually = true);

    try {
      final notifier = ref.read(subscriptionOverviewProvider.notifier);
      // First attempt active verification with PayOS
      await notifier.verifyPayment(widget.paymentLink.orderCode);
      final isPremiumNow = await notifier.checkSubscriptionStatus();

      if (!mounted) return;
      setState(() => _isCheckingManually = false);

      if (isPremiumNow) {
        _pollingTimer?.cancel();
        setState(() => _isSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hệ thống chưa nhận được thanh toán. Vui lòng quét mã trên PayOS hoặc sử dụng chế độ Test bên dưới.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingManually = false);
      }
    }
  }

  Future<void> _simulateSuccess() async {
    if (_isSimulating || _isSuccess) return;
    setState(() => _isSimulating = true);

    try {
      final notifier = ref.read(subscriptionOverviewProvider.notifier);
      final success = await notifier.simulatePayment(widget.paymentLink.orderCode);

      if (!mounted) return;
      setState(() => _isSimulating = false);

      if (success) {
        _pollingTimer?.cancel();
        setState(() => _isSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mô phỏng thanh toán. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessCelebration();
    }

    const goldColor = Color(0xFFD4AF37);

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Rời khỏi trang thanh toán?'),
            content: const Text(
              'Giao dịch của bạn vẫn đang được xử lý. Bạn có thể quay lại trang hội viên để xem trạng thái bất cứ lúc nào.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Ở lại chờ'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Rời khỏi'),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Animated Pulse Avatar
              ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 44,
                      color: goldColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Đang Chờ Thanh Toán...',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng mở liên kết PayOS hoặc quét mã QR ngân hàng để hoàn tất đăng ký gói Premium.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Transaction Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildInfoRow('Mã đơn hàng', '#${widget.paymentLink.orderCode}'),
                    const Divider(height: 20, color: AppColors.divider),
                    _buildInfoRow('Số tiền', widget.paymentLink.formattedAmount, isBold: true),
                    const Divider(height: 20, color: AppColors.divider),
                    _buildInfoRow('Gói đăng ký', 'Premium (30 ngày)'),
                    const Divider(height: 20, color: AppColors.divider),
                    _buildInfoRow('Phương thức', 'VietQR / Banking'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Re-open PayOS button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _reopenPayOS,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Mở lại trang thanh toán PayOS',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Manual Check Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingManually ? null : _manualCheck,
                  icon: _isCheckingManually
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(_isCheckingManually ? 'Đang kiểm tra...' : 'Tôi đã chuyển khoản xong'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sandbox / Developer Simulation Button (Vital for local testing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: goldColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.developer_mode_rounded, size: 16, color: goldColor.withOpacity(0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'Chế độ Thử nghiệm (Test Mode)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Khi test trên localhost, PayOS không thể gọi Webhook về máy. Bạn có thể nhấn nút dưới để hoàn tất ngay:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSimulating ? null : _simulateSuccess,
                        icon: _isSimulating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(
                          _isSimulating ? 'Đang kích hoạt...' : 'Mô phỏng thanh toán thành công',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9E7D3B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Note
              const Text(
                'Hệ thống tự động kiểm tra mỗi 3 giây. Ngay khi giao dịch được xác nhận, tài khoản của bạn sẽ lập tức được nâng cấp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
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
              Text(
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
