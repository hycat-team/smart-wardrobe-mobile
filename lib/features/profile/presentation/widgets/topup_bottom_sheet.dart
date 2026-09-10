import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';

class TopUpBottomSheet extends ConsumerStatefulWidget {
  const TopUpBottomSheet({super.key});

  @override
  ConsumerState<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends ConsumerState<TopUpBottomSheet> {
  final TextEditingController _amountController = TextEditingController(text: '100000');
  double _selectedAmount = 100000;
  bool _isCreatingTopUp = false;

  final List<double> _presets = [50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toInt().toString();
    });
  }

  String _formatCurrency(double amount) {
    final a = amount.toInt();
    final formatted = a.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  Future<void> _handleTopUp() async {
    final entered = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0;
    if (entered < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền nạp tối thiểu là 10.000 đ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreatingTopUp = true);

    try {
      final notifier = ref.read(walletProvider.notifier);
      final returnUrl = kIsWeb
          ? '${Uri.base.origin}/profile'
          : 'smartwardrobe://wallet/topup/success';
      final cancelUrl = kIsWeb
          ? '${Uri.base.origin}/profile'
          : 'smartwardrobe://wallet/topup/cancel';

      final link = await notifier.topUp(entered, returnUrl: returnUrl, cancelUrl: cancelUrl);

      if (!mounted) return;
      setState(() => _isCreatingTopUp = false);

      if (link != null && link.paymentUrl.isNotEmpty) {
        Navigator.pop(context);

        final uri = Uri.parse(link.paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        if (mounted) {
          context.push('/profile/subscription/waiting', extra: link);
        }
      } else {
        final err = ref.read(walletProvider).errorMessage ?? 'Không thể tạo mã VietQR. Vui lòng thử lại!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingTopUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_card_rounded, color: goldColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nạp Tiền Vào Ví Closy',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cổng VietQR / Chuyển khoản ngân hàng 24/7',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Chọn mệnh giá nạp nhanh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((preset) {
              final isSelected = _selectedAmount == preset;
              return InkWell(
                onTap: () => _selectPreset(preset),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _formatCurrency(preset),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Hoặc nhập số tiền tùy ý (tối thiểu 10.000 đ)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
            decoration: InputDecoration(
              suffixText: 'VNĐ',
              suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0;
              setState(() => _selectedAmount = parsed);
            },
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _isCreatingTopUp ? null : _handleTopUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isCreatingTopUp
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tạo Mã VietQR Thanh Toán',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
