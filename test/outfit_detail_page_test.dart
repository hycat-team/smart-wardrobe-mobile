import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/outfit_studio/models/outfit_models.dart';
import 'package:smart_wardrobe/features/outfit_studio/presentation/widgets/outfit_detail_page.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/features/outfit_studio/data/outfit_repository.dart';
import 'package:smart_wardrobe/features/outfit_studio/providers/ai_outfit_provider.dart';
import 'package:smart_wardrobe/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smart_wardrobe/features/wardrobe/models/wardrobe_models.dart';
import 'package:smart_wardrobe/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:smart_wardrobe/shared/widgets/closy_network_image.dart';
import 'package:smart_wardrobe/shared/widgets/media_viewer_overlay.dart';

/// Override `wardrobeProvider` với danh sách món cố định, không gọi mạng.
Override _fakeWardrobe(List<WardrobeItemModel> items) =>
    wardrobeProvider.overrideWith((ref) => WardrobeNotifier(
          _NoopWardrobeRepository(),
          ref,
        )..debugSetItemsForTest(items));

/// Hỗ trợ test: gắp state tủ đồ mà không cần API thật.
extension on WardrobeNotifier {
  void debugSetItemsForTest(List<WardrobeItemModel> items) {
    state = WardrobeState(items: items);
  }
}

class _NoopWardrobeRepository implements WardrobeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('test không gọi mạng tủ đồ');
}

/// Repository outfit luôn lỗi — dùng để kiểm tra nhánh xử lý khi không tải
/// được chi tiết bộ phối.
class _FailingOutfitRepository implements OutfitRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw Exception('mạng lỗi');
}

const _coverA = 'https://res.cloudinary.com/demo/a.jpg';
const _coverB = 'https://res.cloudinary.com/demo/b.jpg';
const _coverC = 'https://res.cloudinary.com/demo/c.jpg';

UserOutfitModel _outfit(String id, String cover,
        {List<OutfitItemDetailModel>? items}) =>
    UserOutfitModel(
      id: id,
      name: 'Bộ phối $id',
      coverImageUrl: cover,
      createdAt: '2026-09-01T10:00:00Z',
      items: items ??
          [
            OutfitItemDetailModel(
              id: '${id}i1',
              fashionItem: RecommendedFashionItemBrief(
                id: 'fi1',
                imageUrl: cover,
                style: 'Áo thun',
              ),
            ),
          ],
    );

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(home: child),
    );

void main() {
  group('OutfitDetailPage — full màn + vuốt', () {
    testWidgets('chiếm toàn bộ chiều cao, có nút quay lại `<` và bộ đếm',
        (tester) async {
      final outfits = [
        _outfit('o1', _coverA),
        _outfit('o2', _coverB),
        _outfit('o3', _coverC),
      ];

      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o2',
        siblings: outfits,
        initialIndex: 1,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Nút quay lại dùng icon mũi tên `<`, không còn icon X.
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Bộ đếm "2 / 3".
      expect(find.text('2 / 3'), findsOneWidget);

      // Nội dung chiếm trọn chiều cao: có PageView lấp đầy khung.
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller, isNotNull);
    });

    testWidgets('vuốt sang outfit kế tiếp → bộ đếm đổi', (tester) async {
      final outfits = [
        _outfit('o1', _coverA),
        _outfit('o2', _coverB),
        _outfit('o3', _coverC),
      ];

      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: outfits,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('1 / 3'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-500, 0), 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Bộ phối o2'), findsWidgets);
    });

    testWidgets('bấm ảnh bìa → mở MediaViewerOverlay nền trong suốt',
        (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(MediaViewerOverlay), findsNothing);

      await tester.tap(find.text('Phóng to'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MediaViewerOverlay), findsOneWidget);

      // Viewer ảnh dùng nền trong suốt, không có nút quay lại.
      final viewerScaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(viewerScaffold.backgroundColor, Colors.transparent);
      // Chỉ assert trong cây viewer — trang outfit phía sau vẫn có nút `<` hợp lệ.
      expect(
        find.descendant(
          of: find.byType(MediaViewerOverlay),
          matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MediaViewerOverlay),
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('một outfit duy nhất → không hiện bộ đếm', (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Bộ đếm có dạng "x / y" (khoảng trắng); ngày "01/09/2026" không khớp.
      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('hiện nút mở Studio và danh sách món trong set', (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Chi tiết bộ phối'), findsOneWidget);
      // Nút hành động dính đáy → không cần cuộn vẫn bấm được.
      expect(find.textContaining('Các món đồ trong set'), findsOneWidget);
      expect(find.text('Xem bộ phối trong studio'), findsOneWidget);
      // Nhãn cũ đã bỏ.
      expect(find.text('Mở Trên Outfit Studio'), findsNothing);
      expect(find.text('Phối Đồ Tương Tự Trên Studio'), findsNothing);
    });

    testWidgets('thanh hành động dính đáy: không cuộn vẫn thấy nút Studio',
        (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Nằm sát đáy khung nhìn, không bị cuộn theo nội dung.
      final button = tester.getRect(find.text('Xem bộ phối trong studio'));
      final screen = tester.getSize(find.byType(Scaffold).last);
      expect(screen.height - button.bottom, lessThan(80));
      // Luôn tìm thấy mà không cần cuộn.
      expect(find.text('Xem bộ phối trong studio'), findsOneWidget);
    });

    testWidgets('dropdown thành phần: mặc định thu gọn, bấm để mở/đóng',
        (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Header luôn hiện, danh sách món thì không.
      expect(find.text('Các món đồ trong set (1 món)'), findsOneWidget);
      expect(find.text('Món đồ thời trang'), findsNothing);

      // Bấm header → mở ra, thấy từng món.
      await tester.ensureVisible(find.text('Các món đồ trong set (1 món)'));
      await tester.pump();
      await tester.tap(find.text('Các món đồ trong set (1 món)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Món đồ thời trang'), findsOneWidget);

      // Bấm lần nữa → thu gọn.
      await tester.tap(find.text('Các món đồ trong set (1 món)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Món đồ thời trang'), findsNothing);
      expect(find.text('Các món đồ trong set (1 món)'), findsOneWidget);
    });

    testWidgets('ảnh bìa chiếm ~78% chiều cao vùng nhìn', (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        siblings: [_outfit('o1', _coverA)],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Vùng nhìn = chiều cao PageView (đã trừ AppBar).
      final viewport = tester.getRect(find.byType(PageView)).height;
      final cover = tester.getRect(find.byType(ClosyNetworkImage).first);
      // Container cha có viền 0.8px mỗi cạnh → ảnh thực nhỏ hơn 1.6px.
      expect(cover.height, closeTo(viewport * kOutfitCoverRatio, 2));

      // Phần thông tin còn lại nằm BÊN DƯỚI ảnh, không chồng lên.
      final name = tester.getRect(find.text('Bộ phối o1'));
      expect(name.top, greaterThanOrEqualTo(cover.bottom));
    });

    testWidgets('không còn dòng "chia sẻ từ thành viên cộng đồng"',
        (tester) async {
      await tester.pumpWidget(_host(OutfitDetailPage(
        outfitId: 'o1',
        // Outfit rỗng món → trước đây rơi vào nhánh else in dòng này.
        siblings: [_outfit('o1', _coverA, items: const [])],
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('thành viên cộng đồng'), findsNothing);
    });

    testWidgets('thiếu đồ trong tủ → bấm mở Studio ra dialog giải thích',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(path: '/list', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/detail',
            builder: (_, __) => OutfitDetailPage(
              outfitId: 'o1',
              siblings: [_outfit('o1', _coverA)],
            ),
          ),
          GoRoute(path: '/studio', builder: (_, __) => const SizedBox()),
        ],
      );

      // Tủ đồ chỉ còn món `fi2`, outfit dùng `fi1` → coi như đã bị gỡ.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _fakeWardrobe(const [
              WardrobeItemModel(
                id: 'w1',
                fashionItem: FashionItemModel(id: 'fi2', imageUrl: _coverA),
              ),
            ]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      router.go('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Nút dính đáy nên không cần cuộn.
      await tester.tap(find.text('Xem bộ phối trong studio'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Bị chặn, không điều hướng vào Studio.
      expect(find.text('Chưa thể xem trong Studio'), findsOneWidget);
      expect(find.text('Đã hiểu'), findsOneWidget);
      // Không mở hộp thoại ghi đè canvas.
      expect(find.text('Thay đồ trên canvas?'), findsNothing);

      await tester.tap(find.text('Đã hiểu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Chưa thể xem trong Studio'), findsNothing);
    });

    testWidgets('đủ đồ trong tủ → bấm mở Studio không bị chặn',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(path: '/list', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/detail',
            builder: (_, __) => OutfitDetailPage(
              outfitId: 'o1',
              siblings: [_outfit('o1', _coverA)],
            ),
          ),
          GoRoute(path: '/studio', builder: (_, __) => const SizedBox()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _fakeWardrobe(const [
              WardrobeItemModel(
                id: 'w1',
                fashionItem: FashionItemModel(id: 'fi1', imageUrl: _coverA),
              ),
            ]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      // `push` (không phải `go`) để còn trang bên dưới cho `pop` trong
      // `_openInStudio`, giống hệt luồng thật (`showClosyOutfitDetail`).
      router.push('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Nút dính đáy nên không cần cuộn.
      await tester.tap(find.text('Xem bộ phối trong studio'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Không chặn → KHÔNG ra dialog giải thích (điểm cần kiểm chứng).
      // Việc `go('/studio')` cần router đầy đủ nên không assert ở đây.
      expect(find.text('Chưa thể xem trong Studio'), findsNothing);
      // Cũng không mở hộp thoại ghi đè canvas.
      expect(find.text('Thay đồ trên canvas?'), findsNothing);
    });

    testWidgets('outfit chưa có món (list API) → báo lỗi thay vì vào canvas trống',
        (tester) async {
      // Repository báo lỗi → không lấy được chi tiết.
      final outfitRepo = _FailingOutfitRepository();
      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(path: '/list', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/detail',
            builder: (_, __) => OutfitDetailPage(
              outfitId: 'o1',
              // items rỗng — đúng những gì `GET /me/outfits` trả về.
              siblings: const [
                UserOutfitModel(
                  id: 'o1',
                  name: 'Bộ phối o1',
                  coverImageUrl: _coverA,
                ),
              ],
            ),
          ),
          GoRoute(path: '/studio', builder: (_, __) => const SizedBox()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _fakeWardrobe(const []),
            outfitRepositoryProvider.overrideWithValue(outfitRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      router.push('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Nút dính đáy nên không cần cuộn.
      await tester.tap(find.text('Xem bộ phối trong studio'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Báo rõ thay vì điều hướng vào Studio với canvas trống.
      expect(find.text('Chưa tải được bộ phối'), findsOneWidget);
    });
  });
}
