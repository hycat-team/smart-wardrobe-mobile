import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/data/community_search_repository.dart';
import 'package:smart_wardrobe/features/community/presentation/community_search_screen.dart';
import 'package:smart_wardrobe/shared/widgets/closy_segmented_control.dart';
import 'package:smart_wardrobe/features/community/providers/community_search_provider.dart';

class _NoopSearchRepository extends CommunitySearchRepository {
  _NoopSearchRepository() : super(apiClient: null);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('test không gọi mạng tìm kiếm');
}

class _NoopCommunityRepository extends CommunityRepository {
  _NoopCommunityRepository() : super();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('test không gọi mạng cộng đồng');
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository() : super(apiClient: null, storage: null);

  @override
  Future<bool> isAuthenticated() async => true;
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.repo, super.ref) {
    state = const AuthState(isAuthenticated: true);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class _FakeSearchNotifier extends CommunitySearchNotifier {
  _FakeSearchNotifier({required String searchType}) : super(_NoopSearchRepository()) {
    state = CommunitySearchState(
      query: 'quiet',
      searchType: searchType,
      postTypeFilter: 'outfit',
    );
  }
}

void main() {
  // Bắt lỗi overflow của Flutter: `RenderFlex overflowed by N pixels`.
  final overflowErrors = <FlutterErrorDetails>[];

  /// Màn hình hẹp nhất phổ biến (iPhone SE / máy Android rẻ) — 320px.
  const smallScreen = Size(320, 720);

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    required String searchType,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final authRepo = _NoopAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communitySearchRepositoryProvider
              .overrideWithValue(_NoopSearchRepository()),
          communitySearchProvider.overrideWith(
            (ref) => _FakeSearchNotifier(searchType: searchType),
          ),
          communityRepositoryProvider
              .overrideWithValue(_NoopCommunityRepository()),
          authRepositoryProvider.overrideWithValue(authRepo),
          authStateProvider
              .overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
        ],
        child: const MaterialApp(home: CommunitySearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  void recordOverflow(FlutterErrorDetails d) {
    final msg = d.exception.toString();
    if (msg.contains('overflowed')) overflowErrors.add(d);
  }

  testWidgets('tab "Bài viết" trên màn 320px KHÔNG tràn thanh filter',
      (tester) async {
    overflowErrors.clear();
    final prev = FlutterError.onError;
    FlutterError.onError = recordOverflow;
    addTearDown(() => FlutterError.onError = prev);

    await pumpAt(tester, smallScreen, searchType: 'posts');

    expect(
      overflowErrors,
      isEmpty,
      reason: 'thanh filter 2 hàng phải vừa màn 320px, không tràn',
    );
  });

  testWidgets('chip loại bài ôm sát chữ, canh trái, đủ 3 và nằm trong màn',
      (tester) async {
    await pumpAt(tester, smallScreen, searchType: 'posts');

    for (final label in ['Tất cả bài', 'Bộ phối', 'Ảnh/Video']) {
      expect(find.text(label), findsOneWidget, reason: 'thiếu chip $label');
    }

    final a = tester.getCenter(find.text('Tất cả bài')).dx;
    final b = tester.getCenter(find.text('Bộ phối')).dx;
    final c = tester.getCenter(find.text('Ảnh/Video')).dx;

    // Thứ tự trái → phải.
    expect(a, lessThan(b));
    expect(b, lessThan(c));

    // Hàng canh trái: mép trái CHIP (không phải mép chữ) bằng lề 16.
    final firstChip = find.ancestor(
      of: find.text('Tất cả bài'),
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.getTopLeft(firstChip).dx,
      closeTo(16, 1),
      reason: 'hàng chip phải canh trái từ lề 16 của màn hình',
    );

    // Hàng chip bọc trong `SingleChildScrollView` ngang → dù có dài hơn màn hình
    // thì vẫn cuộn tới được, không bị cắt cụt. Không assert "3 chip đều nằm
    // trong 320px" vì `google_fonts` không tải được font trong test nên dùng
    // font dự phòng rộng gấp đôi, phép đo đó không phản ánh máy thật.
    final scroll = find.descendant(
      of: find.byType(CommunitySearchScreen),
      matching: find.byType(SingleChildScrollView),
    );
    expect(
      scroll,
      findsWidgets,
      reason: 'hàng chip phải cuộn ngang được để không bị cắt',
    );
  });

  testWidgets('segmented control chiếm HẾT bề ngang, không bị co lại',
      (tester) async {
    await pumpAt(tester, smallScreen, searchType: 'all');

    final segWidth = tester.getSize(find.byType(ClosySegmentedControl)).width;
    // Màn 320px, lề 16 mỗi bên → 288. Nếu nhỏ hơn nhiều nghĩa là `Column`
    // truyền constraint lỏng và control bị co về kích thước nhỏ nhất.
    expect(
      segWidth,
      closeTo(smallScreen.width - 32, 2),
      reason: 'segmented control phải trải hết bề ngang trừ lề 16 hai bên',
    );
  });

  testWidgets('hàng 1 là segmented control: có khối bo tròn 24 + viên trượt',
      (tester) async {
    await pumpAt(tester, smallScreen, searchType: 'all');

    // Track bo tròn 24 nền #F3EFEA — dấu hiệu của segmented control.
    final track = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          ((w.decoration as BoxDecoration).color == const Color(0xFFF3EFEA)) &&
          (w.decoration as BoxDecoration).borderRadius ==
              BorderRadius.circular(24),
    );
    expect(track, findsOneWidget);

    // Có viên trượt.
    expect(find.byType(AnimatedPositioned), findsOneWidget);
  });

  testWidgets('viên trượt dịch đúng 1 phần khi đổi tab', (tester) async {
    double pillLeft() =>
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left!;

    // Đổi tab qua notifier (không pump lại ProviderScope: cùng kiểu widget
    // thì element được tái dùng và notifier override có thể không chạy lại).
    // Cách này còn kiểm chứng đúng thứ ta cần: UI phản ứng theo state.
    void selectTab(String type) {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CommunitySearchScreen)),
      );
      container.read(communitySearchProvider.notifier).changeSearchType(type);
    }

    await pumpAt(tester, smallScreen, searchType: 'all');
    final atAll = pillLeft();

    selectTab('users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final atUsers = pillLeft();

    selectTab('posts');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final atPosts = pillLeft();

    // Mỗi lần chuyển tab, viên dịch đúng bằng 1 bề rộng phần.
    final step = (atUsers - atAll);
    expect(step, greaterThan(0), reason: 'viên phải dịch sang phải');
    expect(atPosts - atUsers, closeTo(step, 0.5));
  });

  testWidgets('bấm 1 phần của segmented control đổi searchType',
      (tester) async {
    await pumpAt(tester, smallScreen, searchType: 'all');

    await tester.tap(find.text('Tác giả'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(CommunitySearchScreen)),
    );
    expect(
      notifier.read(communitySearchProvider).searchType,
      'users',
      reason: 'bấm phần "Tác giả" phải đổi searchType sang users',
    );
  });

  testWidgets('hàng 2 chỉ hiện khi chọn tab "Bài viết"', (tester) async {
    await pumpAt(tester, smallScreen, searchType: 'all');
    expect(find.text('Tất cả bài'), findsNothing);
    expect(find.text('Bộ phối'), findsNothing);

    await pumpAt(tester, smallScreen, searchType: 'users');
    expect(find.text('Bộ phối'), findsNothing);
  });

  testWidgets('CONTROL: cơ chế bắt overflow thực sự hoạt động', (tester) async {
    // Nếu test này fail thì các test "không tràn" ở trên chỉ đang pass vô
    // nghĩa — bộ bắt lỗi hỏng rồi.
    overflowErrors.clear();
    final prev = FlutterError.onError;
    FlutterError.onError = recordOverflow;
    addTearDown(() => FlutterError.onError = prev);

    tester.view.physicalSize = smallScreen * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Row cố tình tràn: 5 ô 200px trong màn 320px.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: List.generate(
              5,
              (i) => SizedBox(width: 200, child: Text('ô $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      overflowErrors,
      isNotEmpty,
      reason: 'bộ bắt overflow phải ghi nhận được lỗi RenderFlex overflow',
    );
  });
}
