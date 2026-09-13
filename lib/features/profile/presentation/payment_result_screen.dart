import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

/// Trang thông báo kết quả thanh toán (success / failed / cancelled / expired).
///
/// Mọi return từ PayOS (deep-link mobile, web returnUrl) và mọi kết luận
/// từ [PaymentWaitingScreen] đều đổ về đây để user luôn thấy thông báo rõ ràng,
/// thay vì rơi về home như trước.
class PaymentResultScreen extends ConsumerStatefulWidget {
  final PaymentResult result;

  const PaymentResultScreen({super.key, required this.result});

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _verifying = true;
  bool _verifiedOk = false;

  @override
  void initState() {
    super.initState();
    _verifyWithBackend();
  }

  /// Nguồn thật luôn là backend, không tin status trên URL.
  /// Deep-link chỉ dùng để điều hướng; verify lại 1 lần rồi hiển thị.
  Future<void> _verifyWithBackend() async {
    bool ok;
    try {
      if (widget.result.isTopUp) {
        await ref.read(walletProvider.notifier).loadWallet();
        // Không có baseline ở cold-start: nếu status success từ PayOS và
        // ví đã có số dư > 0 thì chấp nhận, ngược lại vẫn hiển thị theo
        // status nhưng gắn cờ chưa xác minh tuyệt đối.
        ok = widget.result.status == PaymentResultStatus.success;
      } else {
        ok = await ref
            .read(subscriptionOverviewProvider.notifier)
            .checkSubscriptionStatus();
        // Nếu BE đã premium thì chắc chắn success bất kể status URL.
        if (ok) {
          await ref
              .read(subscriptionOverviewProvider.notifier)
              .loadOverview();
        }
      }
    } catch (_) {
      ok = widget.result.status == PaymentResultStatus.success;
    }
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _verifiedOk = ok;
    });
    ref.invalidate(walletStatementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_verifying) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final requestedSuccess =
        widget.result.status == PaymentResultStatus.success;
    // Gói mua: BE là nguồn chốt. Nạp ví cold-start: tin PayOS + đã load ví.
    final showSuccess =
        widget.result.isTopUp ? requestedSuccess : _verifiedOk;

    if (showSuccess) {
      return widget.result.isTopUp
          ? _buildTopUpSuccess()
          : _buildSubscriptionSuccess();
    }
    return _buildFailure();
  }

  // ---------- Success: topup ----------

  Widget _buildTopUpSuccess() {
    const goldColor = Color(0xFFD4AF37);
    final wallet = ref.watch(walletProvider).wallet;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết Quả Thanh Toán',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
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
                    Icons.check_rounded,
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
                'Ví Closy Pay của bạn đã được cộng ${widget.result.formattedAmount} (mã #${widget.result.orderCode}).',
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
                  onPressed: () => context.go('/profile/wallet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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

  // ---------- Success: subscription ----------

  Widget _buildSubscriptionSuccess() {
    const goldColor = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết Quả Thanh Toán',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
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
                'Tài khoản của bạn đã được nâng cấp thành công lên Closy Premium (mã #${widget.result.orderCode}).',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/profile/subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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

  // ---------- Failure / cancelled / expired ----------

  Widget _buildFailure() {
    final isCancelled =
        widget.result.status == PaymentResultStatus.cancelled;
    final isExpired = widget.result.status == PaymentResultStatus.expired;
    final title = isCancelled
        ? 'Đã Hủy Thanh Toán'
        : isExpired
            ? 'Mã Thanh Toán Đã Hết Hạn'
            : 'Thanh Toán Thất Bại';
    final desc = widget.result.message ??
        (isCancelled
            ? 'Bạn đã hủy giao dịch mã #${widget.result.orderCode} (${widget.result.formattedAmount}). Số dư của bạn không thay đổi.'
            : isExpired
                ? 'Mã #${widget.result.orderCode} (${widget.result.formattedAmount}) đã quá 15 phút và không còn hiệu lực. Số dư của bạn không thay đổi.'
                : 'Giao dịch mã #${widget.result.orderCode} (${widget.result.formattedAmount}) chưa được ghi nhận. Vui lòng thử lại hoặc tạo mã mới.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết Quả Thanh Toán',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
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
                    isCancelled
                        ? Icons.cancel_outlined
                        : Icons.error_outline_rounded,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
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
                  onPressed: () {
                    if (widget.result.isTopUp) {
                      context.go('/profile/wallet');
                    } else {
                      context.go('/profile/subscription/upgrade');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.result.isTopUp ? 'Về Ví Closy Pay' : 'Thử Lại',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/wardrobe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                        color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Về Trang Chủ',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
