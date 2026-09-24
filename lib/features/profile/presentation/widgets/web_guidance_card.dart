import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Hướng dẫn tiếp tục thanh toán / nạp ví trên website — dạng văn bản
/// thuần túy, KHÔNG nút, KHÔNG liên kết, KHÔNG WebView, KHÔNG QR.
///
/// Cố tình không dùng `url_launcher` hay bất kỳ `onTap` mở trình duyệt nào:
/// người dùng tự mở trình duyệt ngoài app và nhập địa chỉ bên dưới.
/// Đây là yêu cầu tuân thủ chính sách cửa hàng ứng dụng (FR-002/FR-006).
class WebGuidanceCard extends StatelessWidget {
  /// Địa chỉ website duy nhất của app (nguồn duy nhất — single source
  /// of truth cho mọi màn hình gói/ví). Hiển thị dạng văn bản để người
  /// dùng tự nhập vào trình duyệt, không gắn tham số gói/số tiền/user.
  static const websiteHost = 'closy.hycat.online';

  /// Copy lỗi tải dữ liệu dùng chung (tiếng Việt + bước tiếp theo).
  static const loadErrorText =
      'Không thể tải dữ liệu. Vui lòng kiểm tra kết nối mạng và thử lại.';

  /// Copy khi quay lại app mà giao dịch web chưa hoàn tất.
  static const pendingHintText =
      'Giao dịch trên website chưa hoàn tất. Vui lòng kiểm tra lại sau ít phút.';

  /// Hành động người dùng định làm trên web: 'mua gói' hoặc 'nạp ví'.
  final String actionLabel;

  /// True khi hiển thị thay cho mã thanh toán cũ đã hết hiệu lực (FR-009).
  final bool isExpiredNotice;

  const WebGuidanceCard({
    super.key,
    this.actionLabel = 'mua gói',
  }) : isExpiredNotice = false;

  const WebGuidanceCard.expired({super.key})
      : actionLabel = 'mua gói / nạp ví',
        isExpiredNotice = true;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: goldColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isExpiredNotice
                      ? 'Mã thanh toán cũ đã hết hiệu lực'
                      : 'Tiếp tục $actionLabel trên website',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isExpiredNotice)
            const Text(
              'Mã thanh toán tạo từ phiên bản trước không còn dùng được. '
              'Vui lòng thực hiện lại trên website theo các bước dưới đây.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            )
          else
            const Text(
              'Để tuân thủ chính sách cửa hàng ứng dụng, Closy không thu tiền trong app. '
              'Vui lòng tiếp tục trên website:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              websiteHost,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildStep(
            number: '1',
            text: 'Mở trình duyệt (Chrome/Safari) và nhập địa chỉ website ở trên.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: '2',
            text: 'Đăng nhập website bằng đúng tài khoản đang dùng trên app (cùng email/số điện thoại).',
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: '3',
            text:
                'Hoàn tất $actionLabel trên website rồi quay lại app — gói và số dư sẽ tự cập nhật.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Giá cuối cùng theo website tại thời điểm thanh toán.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: goldColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: goldColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
