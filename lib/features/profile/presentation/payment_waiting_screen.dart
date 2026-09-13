import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';
import '../utils/payment_link_opener.dart';

/// Màn hình chờ thanh toán PayOS dùng chung cho nạp ví và mua gói.
///
/// Caller BẮT BUỘC truyền [PendingPayment] với đúng số tiền / loại giao dịch
/// (xem [PendingPayment.topUp] và [PendingPayment.purchase]).
/// Trạng thái thật luôn lấy từ backend qua polling, không tin returnUrl.
class PaymentWaitingScreen extends ConsumerStatefulWidget {
  final PendingPayment pending;

  const PaymentWaitingScreen({super.key, required this.pending});

  @override
  ConsumerState<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends ConsumerState<PaymentWaitingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _pollingTimer;
  int _secondsElapsed = 0;
  bool _isSuccess = false;
  bool _isExpired = false;
  bool _isChecking = false;
  bool _navigatedToResult = false;
  late AnimationController _pulseController;

  static const int _fastPhaseSeconds = 120;
  static const int _expirySeconds = 900;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scheduleNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User quay lại app từ browser / app ngân hàng (nút back hệ thống,
    // app-switch): verify ngay thay vì đợi lượt poll tiếp theo.
    if (state == AppLifecycleState.resumed) {
      _checkNow(silent: true);
    }
  }

  /// Polling lùi dần: 3s trong 2 phút đầu, sau đó 10s tới tối đa 15 phút.
  void _scheduleNext() {
    final interval = _secondsElapsed < _fastPhaseSeconds ? 3 : 10;
    _pollingTimer = Timer(Duration(seconds: interval), () async {
      if (!mounted) return;
      setState(() => _secondsElapsed += interval);

      final done = await _checkOnce();
      if (!mounted) return;

      if (done) {
        _onSuccess();
        return;
      }
      if (_secondsElapsed >= _expirySeconds || widget.pending.isExpired) {
        _pollingTimer?.cancel();
        _onExpired();
        return;
      }
      _scheduleNext();
    });
  }

  /// Một lượt kiểm tra trạng thái theo đúng loại giao dịch.
  Future<bool> _checkOnce() async {
    if (widget.pending.isTopUp) {
      try {
        await ref.read(walletProvider.notifier).loadWallet();
        final current = ref.read(walletProvider).wallet.balance;
        return current >=
            widget.pending.baselineBalance + widget.pending.amount - 0.5;
      } catch (_) {
        return false;
      }
    }
    return ref.read(subscriptionOverviewProvider.notifier).checkSubscriptionStatus();
  }

  void _onSuccess() {
    _pollingTimer?.cancel();
    ref.invalidate(walletStatementsProvider);
    if (!widget.pending.isTopUp) {
      ref.read(subscriptionOverviewProvider.notifier).loadOverview();
    } else {
      ref.read(walletProvider.notifier).loadWallet();
    }
    // Direct về trang thông báo kết quả để user luôn thấy success,
    // thay vì ở lại màn chờ hoặc rơi về home khi app restart.
    if (_navigatedToResult || !mounted) {
      if (mounted) setState(() => _isSuccess = true);
      return;
    }
    _navigatedToResult = true;
    if (mounted) setState(() => _isSuccess = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '/profile/payment/result',
        extra: PaymentResult.fromPending(
          widget.pending,
          PaymentResultStatus.success,
        ),
      );
    });
  }

  void _onExpired() {
    if (_navigatedToResult || !mounted) {
      if (mounted) setState(() => _isExpired = true);
      return;
    }
    _navigatedToResult = true;
    if (mounted) setState(() => _isExpired = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '/profile/payment/result',
        extra: PaymentResult.fromPending(
          widget.pending,
          PaymentResultStatus.expired,
          message:
              'Mã #${widget.pending.orderCode} (${widget.pending.formattedAmount}) đã quá 15 phút và không còn hiệu lực. Số dư của bạn không thay đổi.',
        ),
      );
    });
  }

  /// Nút "Tôi đã thanh toán" — kiểm tra ngay thay vì đợi lượt poll tiếp theo.
  /// [silent] dùng cho auto-check khi resume: success thì direct về trang
  /// thông báo, fail thì im lặng để poll tiếp, không spam SnackBar.
  Future<void> _checkNow({bool silent = false}) async {
    if (_isChecking || _isSuccess || _isExpired || _navigatedToResult) return;
    setState(() => _isChecking = true);
    final done = await _checkOnce();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (done) {
      _onSuccess();
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa ghi nhận thanh toán. Nếu bạn vừa chuyển khoản, vui lòng đợi thêm ít phút rồi thử lại.'),
        ),
      );
    }
  }

  Future<void> _reopenPayOS() async {
    await openPaymentLink(
      context,
      paymentUrl: widget.pending.paymentUrl,
      orderCode: widget.pending.orderCode,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      return _buildSuccess();
    }
    if (_isExpired) {
      return _buildExpired();
    }

    const goldColor = Color(0xFFD4AF37);
    final pending = widget.pending;

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
            pending.isTopUp ? 'Nạp Tiền PayOS' : 'Thanh Toán PayOS',
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

              // Order detail card — số tiền / nhãn lấy từ PendingPayment, không hardcode
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
                    _buildInfoRow('Mã đơn hàng', '#${pending.orderCode}', isBold: true),
                    const Divider(height: 24),
                    _buildInfoRow('Số tiền', pending.formattedAmount, isBold: true),
                    const Divider(height: 24),
                    if (pending.isTopUp)
                      _buildInfoRow('Loại giao dịch', 'Nạp ví Closy Pay')
                    else
                      _buildInfoRow('Gói đăng ký', pending.label),
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

              // Button: I have paid — check immediately
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkNow,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.verified_outlined, size: 18),
                  label: Text(
                    _isChecking ? 'Đang kiểm tra...' : 'Tôi Đã Thanh Toán',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
              Text(
                pending.isTopUp
                    ? 'Hệ thống tự động kiểm tra định kỳ. Ngay khi giao dịch được xác nhận, số dư ví của bạn sẽ được cộng ngay.'
                    : 'Hệ thống tự động kiểm tra định kỳ. Ngay khi giao dịch được xác nhận, tài khoản của bạn sẽ lập tức được nâng cấp.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? const Color(0xFFD4AF37) : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    if (widget.pending.isTopUp) {
      return _buildTopUpSuccess();
    }
    return _buildSubscriptionSuccess();
  }

  Widget _buildTopUpSuccess() {
    const goldColor = Color(0xFFD4AF37);
    final wallet = ref.watch(walletProvider).wallet;
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
                    Icons.account_balance_wallet_rounded,
                    size: 60,
                    color: goldColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nạp Tiền Thành Công!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ví Closy Pay của bạn đã được cộng ${widget.pending.formattedAmount}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Số dư hiện tại: ${wallet.formattedBalance}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: goldColor,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(walletProvider.notifier).loadWallet();
                    ref.invalidate(walletStatementsProvider);
                    context.go('/profile/wallet');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Về Ví Closy Pay',
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

  Widget _buildSubscriptionSuccess() {
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

  Widget _buildExpired() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade300, width: 3),
                ),
                child: Center(
                  child: Icon(
                    Icons.timer_off_outlined,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Mã Thanh Toán Đã Hết Hạn',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã #${widget.pending.orderCode} (${widget.pending.formattedAmount}) đã quá 15 phút và không còn hiệu lực. Số dư của bạn không thay đổi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Tạo Mã Mới',
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
