import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/profile_provider.dart';
import '../../../../core/config/release_flags.dart';
import 'topup_bottom_sheet.dart';

class ClosyWalletCard extends ConsumerStatefulWidget {
  const ClosyWalletCard({super.key});

  @override
  ConsumerState<ClosyWalletCard> createState() => _ClosyWalletCardState();
}

class _ClosyWalletCardState extends ConsumerState<ClosyWalletCard> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    // Ẩn toàn bộ thẻ ví ở bản phát hành Play (spec 008, FR-021).
    if (!ReleaseFlags.enablePaidFeatures) {
      return const SizedBox.shrink();
    }
    final walletState = ref.watch(walletProvider);
    final wallet = walletState.wallet;
    const goldColor = Color(0xFFD4AF37);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E242B),
            Color(0xFF12161A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: goldColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldColor.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: goldColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: goldColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'VÍ CLOSY PAY',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _hideBalance = !_hideBalance),
                      tooltip: _hideBalance ? 'Hiện số dư' : 'Ẩn số dư',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Số dư khả dụng',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                walletState.isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: goldColor),
                        ),
                      )
                    : Text(
                        _hideBalance ? '•••••••• đ' : wallet.formattedBalance,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: goldColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      // Nạp ví thực hiện trên website — văn bản thuần túy,
                      // không nút mở link (FR-004/FR-006).
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language_rounded, size: 18, color: goldColor),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Nạp ví trên web: closy.hycat.online',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/profile/wallet'),
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: const Text(
                          'Lịch Sử',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.9),
                          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
