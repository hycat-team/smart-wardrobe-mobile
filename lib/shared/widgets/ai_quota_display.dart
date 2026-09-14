import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Hiển thị 1 dòng hạn mức AI dùng chung cho trang Hồ sơ cá nhân và
/// trang Gói Hội Viên & Hạn Mức (US4).
///
/// Chuẩn hiển thị duy nhất: `"$used/$limit lượt"` (vd `0/5 lượt`) +
/// số lượt còn lại + thanh tiến trình + ghi chú reset 00:00.
///
/// KHÔNG bao giờ render số mặc định khi chưa có số liệu thật:
/// [isLoading] (lần đầu) → skeleton; [errorMessage] (lần đầu) → lỗi + thử lại.
class AiQuotaDisplay extends StatelessWidget {
  final String title;
  final IconData icon;
  final int used;
  final int limit;

  /// true: render trên nền đậm (card primary ở Hồ sơ); false: nền sáng.
  final bool dark;

  /// true khi đang tải lần đầu (chưa từng có số liệu).
  final bool isLoading;

  /// Lỗi tải lần đầu (chỉ dùng khi chưa từng có số liệu).
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// Ẩn ghi chú reset khi màn hình cha đã có (trang Gói có ở header section).
  final bool showResetNote;

  const AiQuotaDisplay({
    super.key,
    required this.title,
    required this.icon,
    required this.used,
    required this.limit,
    this.dark = false,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showResetNote = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (errorMessage != null) return _buildError();

    final remaining = (limit - used).clamp(0, limit);
    final progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final exhausted = remaining == 0;

    final titleColor = dark
        ? Colors.white.withOpacity(0.85)
        : AppColors.textSecondary;
    final valueColor = dark
        ? Colors.white
        : (exhausted ? Colors.red.shade700 : AppColors.textSecondary);
    final iconColor =
        dark ? Colors.white.withOpacity(0.8) : AppColors.primary;
    final trackColor =
        dark ? Colors.white.withOpacity(0.12) : AppColors.surfaceSubtle;
    final barColor = progress >= 0.9
        ? (dark ? Colors.orange.shade300 : Colors.orange.shade700)
        : (dark ? AppColors.accentSand : AppColors.primary);
    final noteColor = dark
        ? Colors.white.withOpacity(0.65)
        : AppColors.textMuted;
    final exhaustedColor =
        dark ? Colors.orange.shade200 : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: dark ? 13 : 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: dark ? 12 : 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '$used/$limit lượt',
              style: TextStyle(
                color: valueColor,
                fontSize: dark ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: dark ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(dark ? 4 : 6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: dark ? 5 : 7,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              exhausted
                  ? 'Hết lượt hôm nay — chờ reset 00:00 hoặc nâng cấp gói'
                  : 'Còn $remaining lượt'
                      '${showResetNote ? ' • Tự động reset 00:00' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: exhausted ? FontWeight.w600 : FontWeight.w400,
                color: exhausted ? exhaustedColor : noteColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: dark ? Colors.white70 : AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Đang tải hạn mức...',
          style: TextStyle(
            fontSize: 12,
            color: dark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final color = dark ? Colors.white : AppColors.textSecondary;
    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Không tải được hạn mức',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(44, 36),
            ),
            child: const Text('Thử lại'),
          ),
      ],
    );
  }
}
