import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/profile/utils/avatar_actions.dart';
import 'package:smart_wardrobe/shared/widgets/media_viewer_overlay.dart';

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

Future<void> _pumpSheet(WidgetTester tester) async {
  final authRepo = _NoopAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAvatarActionSheet(
                  context,
                  hasAvatar: true,
                  onView: () => openMediaViewer(context,
                      imageUrls: const ['https://example.test/a.jpg']),
                  onPick: () {},
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sheet có đúng 2 lựa chọn: Xem ảnh đại diện / Chọn ảnh đại diện',
      (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Xem ảnh đại diện'), findsOneWidget);
    expect(find.text('Chọn ảnh đại diện'), findsOneWidget);
  });

  testWidgets('UI giống các drawer khác: full-width, không lề lọt, không tiêu đề',
      (tester) async {
    await _pumpSheet(tester);

    // Full-width: sheet trải hết bề ngang màn hình (không phải thẻ lọt
    // trong có margin 16 hai bên như bản cũ).
    final tile = find.widgetWithText(ListTile, 'Xem ảnh đại diện');
    final sheetWidth = tester.getSize(tile).width;
    expect(
      sheetWidth,
      greaterThan(300),
      reason: 'sheet phải trải gần hết chiều ngang màn hình',
    );

    // Không có tiêu đề (user chọn phương án không tiêu đề).
    expect(find.text('Ảnh đại diện'), findsNothing);

    // ListTile không kèm dòng mô tả.
    for (final t in tester.widgetList<ListTile>(find.byType(ListTile))) {
      expect(t.subtitle, isNull, reason: 'các option không có dòng mô tả');
    }

    // Icon nằm trong vòng tròn nền surfaceSubtle — marker của các drawer chuẩn.
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.padding == const EdgeInsets.all(10) &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('Chưa có ảnh thì ẩn "Xem ảnh đại diện", chỉ còn "Chọn ảnh đại diện"',
      (tester) async {
    final authRepo = _NoopAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          authStateProvider
              .overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAvatarActionSheet(
                  context,
                  hasAvatar: false,
                  onView: () {},
                  onPick: () {},
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('Xem ảnh đại diện'), findsNothing);
    expect(find.text('Chọn ảnh đại diện'), findsOneWidget);
  });

  testWidgets('Bấm "Xem ảnh đại diện" thì đóng sheet và mở ảnh toàn màn hình',
      (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.text('Xem ảnh đại diện'));
    // Không dùng pumpAndSettle: overlay ảnh có CircularProgressIndicator quay
    // liên tục khi mạng bị chặn trong test nên không bao giờ "settle".
    await tester.pump(); // sheet bắt đầu đóng
    await tester.pump(const Duration(milliseconds: 400)); // đóng xong
    await tester.pump(const Duration(milliseconds: 400)); // dialog ảnh vào

    // Sheet đã đóng, overlay xem ảnh đã mở.
    expect(find.text('Chọn ảnh đại diện'), findsNothing);
    expect(find.byType(MediaViewerOverlay), findsOneWidget);
  });
}
