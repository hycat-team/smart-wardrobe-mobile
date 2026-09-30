import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/core/theme/app_theme.dart';

/// Regression cho lỗi UI "hint text màu đen" trên toàn app.
///
/// Nguyên nhân gốc: `ThemeData` của Flutter cho theme sáng đặt
/// `hintColor = Colors.black` @ 60% — gần như đen. Mọi `TextField` không
/// khai báo `hintStyle` riêng đều nhận màu này, lệch hẳn bảng màu Quiet
/// Luxury (xám muted) và dễ bị hiểu nhầm là đã nhập chữ.
void main() {
  testWidgets('theme đặt hintColor = textSecondary (không phải đen)', (tester) async {
    late Color themeHint;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            themeHint = Theme.of(context).hintColor;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(themeHint, AppColors.textSecondary);
    expect(
      themeHint.computeLuminance(),
      greaterThan(0.1),
      reason: 'hint phải là xám nhạt, không phải đen',
    );
  });

  testWidgets('ô nhập không khai báo hintStyle vẫn nhận màu muted', (tester) async {
    late Color resolved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final decoration =
                const TextField().decoration ?? const InputDecoration();
            resolved = decoration.hintStyle?.color ??
                theme.inputDecorationTheme.hintStyle?.color ??
                theme.hintColor;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, AppColors.textSecondary);
  });

  test('không còn hintStyle nào dùng màu khác textSecondary', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Bỏ qua chính file theme (khai báo hintColor chứ không phải hintStyle).
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('hintStyle')) continue;
        // Gom dòng khai báo + 2 dòng sau (trường hợp xuống dòng).
        final block = lines.sublist(i, (i + 3).clamp(0, lines.length)).join(' ');
        if (!block.contains('AppColors.textSecondary')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'mọi hintStyle phải dùng AppColors.textSecondary — '
          'lệch ở: ${offenders.join(', ')}',
    );
  });
}
