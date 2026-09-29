import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Hệ số phóng lớn của nút lưu (1.2× theo cả chiều rộng và chiều cao).
const double kSaveButtonScale = 1.2;

/// Kích thước gốc của nút lưu trước khi nhân [kSaveButtonScale].
const double _kSaveButtonBaseHeight = 40;
const double _kSaveButtonBasePaddingH = 16;
const double _kSaveButtonBasePaddingV = 10;
const double _kSaveButtonBaseFont = 12;
const double _kSaveButtonBaseIcon = 18;
const double _kSaveButtonBaseSpinner = 14;

/// Chiều cao tối thiểu của nút lưu nổi (đã phóng 1.5×).
const double kFloatingSaveButtonHeight = _kSaveButtonBaseHeight * kSaveButtonScale;

/// Lề an toàn giữa nút lưu nổi và mép khay/dáy vùng vẽ.
const double kFloatingSaveButtonMargin = 12;

/// Khoảng hở giữa nút lưu và mép trên của khay outfit thay thế.
///
/// Đã tăng thêm 0.3cm (≈ 11.3 logical px) so với bản dính sát ban đầu
/// (4px → 15.3px) để nút tách khay rõ hơn, vẫn nằm ngay trên khay và
/// di chuyển đồng bộ tuyệt đối cùng khay.
const double kSaveButtonGap = 15.3;

/// Tính khoảng cách từ **đáy vùng vẽ** tới đáy nút lưu nổi, để nút luôn nằm
/// ngay phía trên khay outfit thay thế và tự trượt lên/xuống theo
/// `drawerSize` (tỉ lệ chiều cao của `DraggableScrollableSheet`).
///
/// - [drawerSize]: 0.065 (gập) · 0.42 (mở vừa) · 0.70 (mở tối đa).
/// - [viewportHeight]: chiều cao vùng vẽ Studio.
/// - Giá trị luôn nằm trong `[margin, viewportHeight - buttonHeight - margin]`
///   để không bị tràn ra ngoài vùng vẽ trên màn hình thấp.
double floatingSaveButtonInset({
  required double drawerSize,
  required double viewportHeight,
  double buttonHeight = kFloatingSaveButtonHeight,
  double margin = kFloatingSaveButtonMargin,
}) {
  final maxInset = viewportHeight - buttonHeight - margin;
  final upperBound = maxInset < margin ? margin : maxInset;
  return (drawerSize * viewportHeight + margin).clamp(margin, upperBound);
}

/// Nút "Lưu Look" nổi — Quiet Luxury: nền trắng bo tròn, shadow nhẹ.
class FloatingSaveLookButton extends StatelessWidget {
  final bool isSaving;
  final bool hasItems;
  final VoidCallback onPressed;

  const FloatingSaveLookButton({
    super.key,
    required this.isSaving,
    required this.hasItems,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isSaving || !hasItems;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * kSaveButtonScale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16 * kSaveButtonScale,
            offset: Offset(0, 4 * kSaveButtonScale),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ElevatedButton.icon(
          onPressed: isBusy ? null : onPressed,
          icon: isSaving
              ? SizedBox(
                  width: _kSaveButtonBaseSpinner * kSaveButtonScale,
                  height: _kSaveButtonBaseSpinner * kSaveButtonScale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.bookmark_border_rounded,
                  size: _kSaveButtonBaseIcon * kSaveButtonScale,
                ),
          label: Text(
            isSaving ? 'Đang lưu' : 'Lưu',
            style: GoogleFonts.beVietnamPro(
              fontSize: _kSaveButtonBaseFont * kSaveButtonScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.4),
            disabledForegroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: _kSaveButtonBasePaddingH * kSaveButtonScale,
              vertical: _kSaveButtonBasePaddingV * kSaveButtonScale,
            ),
            minimumSize: const Size(0, kFloatingSaveButtonHeight),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
