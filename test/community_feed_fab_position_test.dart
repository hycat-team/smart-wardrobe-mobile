import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/community/data/community_repository.dart';
import 'package:smart_wardrobe/features/community/presentation/community_feed_screen.dart';
import 'package:smart_wardrobe/features/community/providers/community_feed_provider.dart';

class _NoopCommunityRepository extends CommunityRepository {
  _NoopCommunityRepository() : super();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('test không gọi mạng feed');
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

class _FakeFeedNotifier extends CommunityFeedNotifier {
  _FakeFeedNotifier(super.repo) : super() {
    state = const CommunityFeedState();
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final authRepo = _NoopAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider
              .overrideWithValue(_NoopCommunityRepository()),
          communityFeedProvider.overrideWith((ref) => _FakeFeedNotifier(_NoopCommunityRepository())),
          authRepositoryProvider.overrideWithValue(authRepo),
          authStateProvider
              .overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
        ],
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Màn có 2 icon "+": nút FAB và nút "Đăng bài ngay" ở trạng thái rỗng.
  // Nên neo mọi assertion vào `tooltip` — duy nhất thuộc FAB.
  Finder fab() => find.byTooltip('Đăng bài');

  testWidgets('nút tạo bài nằm sát phải, không căn giữa màn hình',
      (tester) async {
    const screen = Size(360, 720);
    await pump(tester, screen);

    expect(fab(), findsOneWidget);
    expect(
      tester.getCenter(fab()).dx,
      greaterThan(screen.width / 2),
      reason: 'nút tạo bài phải ở nửa phải màn hình '
          '(trước đây centerFloat nên nằm ở giữa)',
    );
  });

  testWidgets('nút tạo bài tròn 48×48, CHỈ có icon + không kèm chữ',
      (tester) async {
    await pump(tester, const Size(360, 720));

    final size = tester.getSize(fab());
    expect(size.width, closeTo(48, 1), reason: 'chiều rộng phải là 48px');
    expect(size.height, closeTo(48, 1), reason: 'chiều cao phải khớp nút Lưu (48px)');

    // Yêu cầu: chỉ dấu "+", không chữ nào bên cạnh.
    expect(
      find.text('Đăng bài'),
      findsNothing,
      reason: 'nút đã bỏ chữ, chỉ giữ icon +',
    );
  });

  testWidgets('nút tạo bài có nhãn accessibility (tooltip) dù không còn chữ',
      (tester) async {
    await pump(tester, const Size(360, 720));

    // Nút không còn chữ thì `tooltip` là nhãn duy nhất cho trình đọc màn hình
    // và là lối vào tạo bài duy nhất (nút AppBar đã bị gỡ trước đó).
    expect(
      fab(),
      findsOneWidget,
      reason: 'bắt buộc có tooltip khi đã bỏ chữ khỏi nút',
    );
  });
}
