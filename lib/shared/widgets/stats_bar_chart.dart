import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/wardrobe/models/wardrobe_stats_models.dart';

/// Biểu đồ cột xu hướng mặc theo tháng (spec 009, US3).
/// Tự vẽ bằng CustomPainter, không thêm dependency.
/// Hiển thị tối đa 6 điểm gần nhất; khi rỗng hoặc < 2 điểm có số liệu,
/// hiển thị ghi chú "Chưa đủ dữ liệu" thay vì biểu đồ rỗng.
class StatsBarChart extends StatelessWidget {
  final List<TimeTrendPoint> points;
  final double height;

  const StatsBarChart({super.key, required this.points, this.height = 190});

  /// Nhãn tháng rút gọn từ `YYYY-MM` → `T01`..`T12`.
  static String shortMonthLabel(String month) {
    final parts = month.split('-');
    if (parts.length == 2 && parts[1].length == 2) {
      return 'T${parts[1]}';
    }
    return month.length > 5 ? month.substring(month.length - 5) : month;
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _buildPlaceholder(context, 'Chưa đủ dữ liệu để vẽ xu hướng.');
    }
    final recent = points.length > 6 ? points.sublist(points.length - 6) : points;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _StatsBarChartPainter(points: recent),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String message) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}

class _StatsBarChartPainter extends CustomPainter {
  final List<TimeTrendPoint> points;

  _StatsBarChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const labelZone = 26.0; // vùng nhãn tháng phía dưới
    const valueZone = 20.0; // vùng số liệu phía trên
    final maxValue = points
        .map((p) => p.wearCount)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();

    final barAreaHeight = size.height - labelZone - valueZone;
    final slotWidth = size.width / points.length;
    const barFraction = 0.52;

    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.6)
      ..strokeWidth = 0.6;

    final barPaint = Paint()..color = AppColors.accentSandDark;

    final labelStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final centerX = slotWidth * i + slotWidth / 2;
      final barWidth = slotWidth * barFraction;
      final barHeight =
          barAreaHeight * (p.wearCount / maxValue).clamp(0.0, 1.0);
      final top = valueZone + (barAreaHeight - barHeight);
      final bottom = valueZone + barAreaHeight;

      // Lưới nền nhẹ.
      canvas.drawLine(
        Offset(slotWidth * i, top),
        Offset(size.width, top),
        gridPaint,
      );

      // Cột (tối thiểu 2px để luôn thấy được).
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, (top + bottom) / 2),
          width: barWidth,
          height: barHeight < 2 ? 2 : barHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, barPaint);

      // Số liệu trên đầu cột.
      _drawCenteredText(
        canvas,
        '${p.wearCount}',
        valueStyle,
        Offset(centerX, valueZone - 10),
      );

      // Nhãn tháng dưới chân cột.
      _drawCenteredText(
        canvas,
        StatsBarChart.shortMonthLabel(p.month),
        labelStyle,
        Offset(centerX, size.height - labelZone / 2),
      );
    }
  }

  void _drawCenteredText(
      Canvas canvas, String text, TextStyle style, Offset center) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StatsBarChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
