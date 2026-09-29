import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/community/models/post_models.dart';
import 'package:smart_wardrobe/features/community/presentation/widgets/media_grid.dart';
import 'package:smart_wardrobe/shared/widgets/media_viewer_overlay.dart';

PostMedia _img(String url, {int sort = 0}) =>
    PostMedia(id: 'i$sort', mediaType: 'image', mediaUrl: url, sortOrder: sort);

PostMedia _vid(String url, {int sort = 0}) =>
    PostMedia(id: 'v$sort', mediaType: 'video', mediaUrl: url, sortOrder: sort);

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

/// Ảnh mạng không settle trong test nên dùng pump có thời gian thay pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  group('MediaViewerOverlay', () {
    testWidgets('mở từ grid 1 ảnh → overlay toàn màn, có nút đóng',
        (tester) async {
      await tester.pumpWidget(_host(MediaGrid(
        media: [_img('https://res.cloudinary.com/demo/a.jpg')],
        enableVideoPlayer: false,
      )));
      await tester.pump();

      expect(find.byType(MediaViewerOverlay), findsNothing);

      await tester.tap(find.byType(GestureDetector).first);
      await _settle(tester);

      expect(find.byType(MediaViewerOverlay), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      // Nền overlay trong suốt — nền bổ sung 87% đen loại ra từ barrier.
      expect(scaffold.backgroundColor, Colors.transparent);
      // Nền bổ sung phải trong suốt (alpha < 1) như video.
      expect(kMediaViewerBarrierColor.a, lessThan(1.0));
      expect(kMediaViewerBarrierColor, const Color(0xD9000000));
      // 1 ảnh → không hiện bộ đếm "x / N".
      expect(find.textContaining('/ '), findsNothing);

      // KHÔNG có nút quay lại trong overlay (đóng bằng tap vùng trống).
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('chưa zoom thì ảnh CỐ ĐỊNH: pan bị khoá, không có boundaryMargin',
        (tester) async {
      await tester.pumpWidget(_host(MediaViewerOverlay(
        imageUrls: const ['https://res.cloudinary.com/demo/a.jpg'],
      )));
      await _settle(tester);

      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      // Chưa zoom → không kéo được ảnh.
      expect(viewer.panEnabled, isFalse);
      // Vẫn pinch-zoom được.
      expect(viewer.scaleEnabled, isTrue);
      // Không có vùng đệm → kéo tới mép là dừng, không hở viền.
      expect(viewer.boundaryMargin, EdgeInsets.zero);
      // Ảnh được FittedBox vừa khung.
      expect(find.byType(FittedBox), findsWidgets);
    });

    testWidgets('tap lên ảnh KHÔNG đóng, tap vùng trống mới đóng',
        (tester) async {
      await tester.pumpWidget(_host(MediaGrid(
        media: [_img('https://res.cloudinary.com/demo/1.jpg')],
        enableVideoPlayer: false,
      )));
      await tester.pump();

      // Mở qua route thật (showGeneralDialog) để maybePop có nơi pop về.
      await tester.tap(find.byType(GestureDetector).first);
      await _settle(tester);
      expect(find.byType(MediaViewerOverlay), findsOneWidget);

      // Vùng ảnh thực tế (ảnh mạng fail trong test → placeholder ở giữa).
      final imageRect = tester.getRect(find.descendant(
        of: find.byType(MediaViewerOverlay),
        matching: find.byType(FittedBox),
      ));

      // Tap đúng vùng ảnh → vẫn mở.
      await tester.tapAt(imageRect.center);
      await _settle(tester);
      expect(find.byType(MediaViewerOverlay), findsOneWidget);

      // Tap góc ngoài vùng ảnh → đóng.
      await tester.tapAt(const Offset(4, 4));
      await _settle(tester);
      expect(find.byType(MediaViewerOverlay), findsNothing);
    });

    testWidgets('nhiều ảnh → hiện bộ đếm, vuốt đổi ảnh', (tester) async {
      await tester.pumpWidget(_host(SizedBox(
        width: 360,
        height: 300,
        child: MediaGrid(
          media: [
            _img('https://res.cloudinary.com/demo/1.jpg', sort: 1),
            _img('https://res.cloudinary.com/demo/2.jpg', sort: 2),
            _img('https://res.cloudinary.com/demo/3.jpg', sort: 3),
          ],
          enableVideoPlayer: false,
        ),
      )));
      await tester.pump();

      // Ảnh thứ 2 trong layout 3 ảnh.
      final tiles = find.descendant(
        of: find.byType(MediaGrid),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(tiles.at(1));
      await _settle(tester);

      expect(find.byType(MediaViewerOverlay), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await _settle(tester);
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('bấm nền đen để đóng', (tester) async {
      await tester.pumpWidget(_host(MediaGrid(
        media: [_img('https://res.cloudinary.com/demo/1.jpg')],
        enableVideoPlayer: false,
      )));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector).first);
      await _settle(tester);
      expect(find.byType(MediaViewerOverlay), findsOneWidget);

      // Bấm sát mép trên (vùng trống ngoài ảnh) → đóng.
      await tester.tapAt(const Offset(200, 4));
      await _settle(tester);
      expect(find.byType(MediaViewerOverlay), findsNothing);
    });

    testWidgets('overlay dựng được và zoom bằng InteractiveViewer',
        (tester) async {
      await tester.pumpWidget(_host(MediaViewerOverlay(
        imageUrls: const ['https://res.cloudinary.com/demo/broken.jpg'],
      )));
      await tester.pump();

      expect(find.byType(MediaViewerOverlay), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('MediaGrid → viewer (lọc video)', () {
    testWidgets('bài có video + 2 ảnh → overlay chỉ duyệt 2 ảnh',
        (tester) async {
      await tester.pumpWidget(_host(SizedBox(
        width: 360,
        height: 240,
        child: MediaGrid(
          media: [
            _img('https://res.cloudinary.com/demo/1.jpg', sort: 1),
            _vid('https://res.cloudinary.com/demo/v.mp4', sort: 2),
            _img('https://res.cloudinary.com/demo/2.jpg', sort: 3),
          ],
          enableVideoPlayer: false,
        ),
      )));
      await tester.pump();

      // Ảnh đầu tiên trong layout 3 ảnh.
      final tiles = find.descendant(
        of: find.byType(MediaGrid),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(tiles.at(0));
      await _settle(tester);

      expect(find.byType(MediaViewerOverlay), findsOneWidget);
      // Video không tính vào danh sách ảnh.
      expect(find.text('1 / 2'), findsOneWidget);
    });
  });
}
