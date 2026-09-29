import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/presentation/widgets/floating_save_button.dart';

void main() {
  group('floatingSaveButtonInset — neo theo khay outfit thay thế', () {
    const viewport = 500.0;

    test('khay gập (0.065) → nút nằm sát đáy', () {
      final inset = floatingSaveButtonInset(
        drawerSize: 0.065,
        viewportHeight: viewport,
      );
      expect(inset, closeTo(0.065 * viewport + 12, 0.001));
      expect(inset, lessThan(60));
    });

    test('khay mở vừa (0.42) → nút trượt lên', () {
      final inset = floatingSaveButtonInset(
        drawerSize: 0.42,
        viewportHeight: viewport,
      );
      expect(inset, closeTo(0.42 * viewport + 12, 0.001));
    });

    test('khay mở tối đa (0.70) → nút trượt lên tiếp', () {
      final inset = floatingSaveButtonInset(
        drawerSize: 0.70,
        viewportHeight: viewport,
      );
      expect(inset, closeTo(0.70 * viewport + 12, 0.001));
    });

    test('inset tăng đơn điệu theo chiều cao khay', () {
      double prev = -1;
      for (final size in [0.0, 0.065, 0.20, 0.42, 0.70, 1.0]) {
        final inset = floatingSaveButtonInset(
          drawerSize: size,
          viewportHeight: viewport,
        );
        expect(inset, greaterThanOrEqualTo(prev));
        prev = inset;
      }
    });

    test('kẹp trong vùng an toàn khi khay mở tối đa trên màn thấp', () {
      final small = 150.0;
      final inset = floatingSaveButtonInset(
        drawerSize: 0.70,
        viewportHeight: small,
      );
      // Không được tràn ra ngoài vùng vẽ.
      expect(inset, lessThanOrEqualTo(small - kFloatingSaveButtonHeight));
      expect(inset, greaterThanOrEqualTo(kFloatingSaveButtonMargin));
    });

    test('màn quá thấp (viewport < nút + 2 lề) → giữ đúng lề tối thiểu', () {
      final inset = floatingSaveButtonInset(
        drawerSize: 0.70,
        viewportHeight: 30,
      );
      expect(inset, kFloatingSaveButtonMargin);
    });

    test('khe hở nút lưu – khay đã tăng thêm ~0.3cm (≈11.3px)', () {
      // 0.3cm = 0.3 * 96 / 2.54 ≈ 11.34 logical px, cộng khe gốc 4px.
      const gapAddedCm = 0.3;
      final expected = 4 + gapAddedCm * 96 / 2.54;
      expect(kSaveButtonGap, closeTo(expected, 0.05));
    });

    test('nút lưu phóng 1.2× theo cả chiều rộng và chiều cao', () {
      expect(kSaveButtonScale, 1.2);
      // Chiều cao tối thiểu = chiều cao gốc 40px × 1.2.
      expect(kFloatingSaveButtonHeight, closeTo(40 * 1.2, 0.01));
    });
  });

  group('FloatingSaveLookButton', () {
    Widget host({
      required bool isSaving,
      required bool hasItems,
      VoidCallback? onPressed,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: FloatingSaveLookButton(
              isSaving: isSaving,
              hasItems: hasItems,
              onPressed: onPressed ?? () {},
            ),
          ),
        );

    testWidgets('hiện nhãn "Lưu" và bấm được khi canvas có món',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
          host(isSaving: false, hasItems: true, onPressed: () => tapped++));
      await tester.pump();

      expect(find.text('Lưu'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('khi đang lưu → nhãn "Đang lưu" + nút bị khoá',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
          host(isSaving: true, hasItems: true, onPressed: () => tapped++));
      await tester.pump();

      expect(find.text('Đang lưu'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('canvas trống → nút bị khoá', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
          host(isSaving: false, hasItems: false, onPressed: () => tapped++));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(tapped, 0);
    });
  });
}
