import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/community/data/user_social_repository.dart';
import 'package:smart_wardrobe/features/community/models/profile_models.dart';
import 'package:smart_wardrobe/features/community/models/search_models.dart';
import 'package:smart_wardrobe/features/community/presentation/widgets/user_follows_sheet.dart';

class _NoopSocialRepository extends UserSocialRepository {
  _NoopSocialRepository() : super(apiClient: null);

  @override
  Future<PaginationResult<FollowUser>> getUserFollows(
    String username, {
    String? type = 'following',
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginationResult<FollowUser>(
      items: const [],
      metadata: PaginationMetadata(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<void> followUser(String username, {required bool isFollowing}) async {}
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

/// Mở UserFollowsSheet trong một route để có thể kiểm tra dismiss.
Future<void> _pump(WidgetTester tester) async {
  final authRepo = _NoopAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userSocialRepositoryProvider
            .overrideWithValue(_NoopSocialRepository()),
        authRepositoryProvider.overrideWithValue(authRepo),
        authStateProvider
            .overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const UserFollowsSheet(
                    username: 'linh',
                    initialType: 'followers',
                  ),
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
  testWidgets('Thứ tự tab: "Người theo dõi" trước, "Đang theo dõi" sau',
      (tester) async {
    await _pump(tester);

    expect(find.text('Người theo dõi'), findsOneWidget);
    expect(find.text('Đang theo dõi'), findsOneWidget);

    final followersX = tester.getCenter(find.text('Người theo dõi')).dx;
    final followingX = tester.getCenter(find.text('Đang theo dõi')).dx;
    expect(
      followersX,
      lessThan(followingX),
      reason: '"Người theo dõi" phải nằm bên trái "Đang theo dõi"',
    );
  });

  testWidgets('Bấm vùng trống phía trên thì đóng sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pump(tester);
    expect(find.text('Người theo dõi'), findsOneWidget);

    // Vùng trống phía trên sheet (sheet chiếm 65% chiều cao = 520px).
    const logicalW = 360.0;
    const logicalH = 800.0;
    expect(logicalH * 0.65, greaterThan(200));
    await tester.tapAt(const Offset(180, 120));
    await tester.pumpAndSettle();

    expect(
      find.text('Người theo dõi'),
      findsNothing,
      reason: 'bấm vùng trống phía trên (cao 120/${logicalW}x$logicalH) '
          'phải đóng sheet',
    );
  });
}
