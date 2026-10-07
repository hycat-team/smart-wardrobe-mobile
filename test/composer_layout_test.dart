// Spec 015 — US3: màn Up bài không tràn viền ở cửa sổ hẹp.
//
// FR-012 (không tràn ở mọi bề rộng) · FR-013 (nút tự xuống dòng) ·
// FR-014 (bề rộng rộng giữ nguyên bố cục) · FR-015 (bộ đếm + khoá khi đủ 10).
//
// Bối cảnh: trước khi sửa, dải "HÌNH ẢNH & VIDEO" là `Row` + `spaceBetween` chứa
// một `Text` không co giãn và một `Row` lồng chứa hai `TextButton.icon`. Tổng bề
// rộng cố định vượt khung ở cửa sổ hẹp → `RenderFlex overflowed` (đã quan sát thấy
// trong log runtime: 66px dọc, 67px ngang).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/presentation/post_composer_screen.dart';

/// Chỉ cần một instance để provider dựng được notifier. Màn Up bài ở chế độ tạo
/// mới không gọi mạng lúc khởi tạo (chỉ gọi khi `editPublicId` khác null).
class _NoopCommunityRepo extends CommunityRepository {}

/// Dựng màn Up bài trong khung chỉ [width] px.
Future<void> _pumpComposer(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(_NoopCommunityRepo()),
      ],
      child: const MaterialApp(
        home: PostComposerScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// `RenderFlex overflow` trong lúc paint sẽ bị FlutterError ghi nhận và làm test
/// fail. Ở đây ta kiểm tra tường minh cho chắc.
void _expectNoOverflow(WidgetTester tester) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'không được có RenderFlex overflow ở bề rộng này',
  );
}

void main() {
  group('PostComposer — dải media không tràn viền (FR-012)', () {
    testWidgets('cửa sổ hẹp 320px: không overflow, nút vẫn bấm được',
        (tester) async {
      await _pumpComposer(tester, width: 320, height: 900);

      _expectNoOverflow(tester);

      // Hai nút phải CÒN hiện và bấm được (không bị cắt bởi mép khung).
      expect(find.text('Thêm ảnh'), findsOneWidget);
      expect(find.text('Thêm video'), findsOneWidget);

      final addImage = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Thêm ảnh'),
          matching: find.byType(TextButton),
        ),
      );
      expect(addImage.onPressed, isNotNull, reason: 'nút phải bấm được');
    });

    testWidgets('rất hẹp 300px: nút tự xuống dòng, không tràn ngang',
        (tester) async {
      await _pumpComposer(tester, width: 300, height: 1000);

      _expectNoOverflow(tester);
      expect(find.text('Thêm ảnh'), findsOneWidget);
      expect(find.text('Thêm video'), findsOneWidget);
    });

    testWidgets('bề rộng rộng 900px: bố cục không lỗi (FR-014)',
        (tester) async {
      await _pumpComposer(tester, width: 900, height: 1000);

      _expectNoOverflow(tester);
      expect(find.text('HÌNH ẢNH & VIDEO (0/10)'), findsOneWidget);
      expect(find.text('Thêm ảnh'), findsOneWidget);
      expect(find.text('Thêm video'), findsOneWidget);
    });

    testWidgets('tiêu đề dải media luôn hiện đủ (FR-012)',
        (tester) async {
      await _pumpComposer(tester, width: 320, height: 900);
      expect(find.textContaining('HÌNH ẢNH & VIDEO'), findsOneWidget);
    });
  });
}