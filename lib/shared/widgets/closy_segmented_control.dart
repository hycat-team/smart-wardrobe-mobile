import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Một phân đoạn của [ClosySegmentedControl].
class ClosySegmentedItem {
  final String label;
  final IconData? icon;

  const ClosySegmentedItem(this.label, {this.icon});
}

/// Segmented control dùng chung: một khối bo tròn liền mạch, các phần chia
/// đều nhau, có "viên" màu primary trượt sang phần đang chọn.
///
/// Ngôn ngữ thị giác lấy y hệt từ tab switcher của trang Cộng đồng
/// (`community_feed_screen.dart` → `_buildUnifiedTabBar`) để hai màn trông
/// như cùng một hệ thống.
///
/// Vì các phần luôn chia đều trong bề rộng sẵn có nên **không bao giờ tràn**
/// khung, kể cả khi nhãn dài hoặc font lớn hơn dự kiến (nhãn dài sẽ bị
/// `ellipsis` cắt chứ không phóng ra ngoài).
class ClosySegmentedControl extends StatelessWidget {
  final List<ClosySegmentedItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Chiều cao của khối (bao gồm padding trong).
  final double height;

  /// Cỡ chữ nhãn.
  final double labelFontSize;

  const ClosySegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 48,
    this.labelFontSize = 13,
  }) : assert(items.length >= 2, 'segmented control cần ít nhất 2 phần');

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex.clamp(0, items.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Vùng bên trong khối, sau khi trừ padding 4 mỗi bên.
          final innerWidth = constraints.maxWidth - 8;
          final segmentWidth = innerWidth / items.length;

          return Stack(
            children: [
              // Viên trượt — bám sát mép trên/dưới khối, trượt theo vị trí.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                left: segmentWidth * index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Nhãn từng phần, chồng lên viên trượt.
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: labelFontSize,
                              fontWeight: i == index
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color:
                                  i == index ? Colors.white : AppColors.textSecondary,
                              letterSpacing: -0.1,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (items[i].icon != null) ...[
                                  Icon(
                                    items[i].icon,
                                    size: 16,
                                    color: i == index
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
