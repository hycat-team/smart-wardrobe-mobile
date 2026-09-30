import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/profile/data/profile_repository.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';
import 'package:smart_wardrobe/features/profile/presentation/profile_screen.dart';
import 'package:smart_wardrobe/features/profile/presentation/widgets/closy_wallet_card.dart';
import 'package:smart_wardrobe/features/profile/providers/profile_provider.dart';
import 'package:dio/dio.dart';

/// Repository không chạm mạng: mọi lời gọi đều ném lỗi.
class _NoopProfileRepository extends ProfileRepository {
  _NoopProfileRepository() : super(apiClient: null, cloudinaryDio: Dio());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('test không gọi mạng hồ sơ');
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository() : super(apiClient: null, storage: null);

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<UserModel> getCurrentUser() async => throw Exception('no user');
}

Widget _host(List<Override> overrides, Widget child) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => child),
            for (final path in const [
              '/profile/privacy',
              '/profile/wallet',
              '/profile/subscription',
              '/profile/subscription/upgrade',
              '/profile/edit',
              '/profile/change-password',
              '/wardrobe/insights',
              '/wardrobe/statistics',
            ])
              // Marker riêng từng route để assert đã điều hướng.
              GoRoute(
                path: path,
                builder: (_, __) => Scaffold(
                  body: Center(child: Text('ROUTE $path')),
                ),
              ),
            GoRoute(path: '/community', builder: (_, __) => const SizedBox()),
          ],
        ),
      ),
    );

/// Notifier auth giả: luôn ở trạng thái đã đăng nhập, không gọi mạng.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.repo, super.ref) {
    state = const AuthState(isAuthenticated: true);
  }

  @override
  Future<void> checkAuthStatus() async {
    state = const AuthState(isAuthenticated: true);
  }

  @override
  Future<void> logout() async => state = const AuthState();
}

/// Wallet cố định để card Closy Pay render số dư ngay (không ở loading).
class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(super.repo, super.ref) {
    state = const WalletState(
      wallet: WalletModel(userId: 'u1', balance: 125000, currency: 'VND'),
    );
  }

  @override
  Future<void> loadWallet() async {}
}

void main() {
  final authRepo = _NoopAuthRepository();
  final profileRepo = _NoopProfileRepository();
  final overrides = <Override>[
    profileRepositoryProvider.overrideWithValue(profileRepo),
    authRepositoryProvider.overrideWithValue(authRepo),
    authStateProvider.overrideWith(
      (ref) => _FakeAuthNotifier(authRepo, ref),
    ),
    walletProvider.overrideWith((ref) => _FakeWalletNotifier(profileRepo, ref)),
  ];

  group('ProfileScreen — điều hướng menu', () {
    testWidgets('bỏ mục "Cộng đồng thời trang"', (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cộng đồng thời trang'), findsNothing);
    });

    testWidgets('card Closy Pay ẩn số dư mặc định và chỉ có nút Lịch Sử',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tiêu đề ví dùng font Outfit, in hoa: "VÍ CLOSY PAY".
      expect(find.text('VÍ CLOSY PAY'), findsOneWidget);
      expect(find.text('Số dư khả dụng'), findsOneWidget);
      expect(find.text('Xem gói'), findsOneWidget);

      // Số dư mặc định ẩn, hiện con mắt "đang ẩn".
      expect(find.text('•••••••• đ'), findsOneWidget);
      expect(find.text('125.000 đ'), findsNothing);
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

      // Card chỉ còn nút Lịch Sử, không còn nút nạp ví trên web.
      expect(find.text('Lịch Sử'), findsOneWidget);
      expect(find.textContaining('Nạp ví trên web'), findsNothing);
      expect(find.textContaining('closy.hycat.online'), findsNothing);
    });

    testWidgets('xoá mục Gói hội viên & Hạn mức AI và Ví & Lịch sử khỏi menu dưới',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -1200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gói hội viên & Hạn mức AI'), findsNothing);
      expect(find.text('Ví Closy Pay & Lịch sử giao dịch'), findsNothing);
      // Các mục còn lại của khu TÀI KHOẢN & HỆ THỐNG vẫn phải còn.
      expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
    });

    testWidgets('thẻ ví hiện số dư và nút lịch sử (không phụ thuộc cờ paid)',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Thẻ ví không bị thu gọn về SizedBox.shrink().
      expect(find.byType(ClosyWalletCard), findsOneWidget);
      expect(find.text('Số dư khả dụng'), findsOneWidget);
      expect(find.text('Lịch Sử'), findsOneWidget);
    });

    testWidgets('mục Chính sách bảo mật nằm sau Thống kê chi tiết, trước Đăng xuất',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Danh sách dài → cuộn tới từng mục rồi so vị trí.
      double topOf(WidgetTester t, String label) {
        return t.getTopLeft(find.text(label)).dy;
      }

      await tester.scrollUntilVisible(find.text('Thống kê chi tiết'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final stats = topOf(tester, 'Thống kê chi tiết');

      await tester.scrollUntilVisible(find.text('Chính sách bảo mật'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final privacy = topOf(tester, 'Chính sách bảo mật');

      await tester.scrollUntilVisible(find.text('Đăng xuất'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final logout = topOf(tester, 'Đăng xuất');

      expect(privacy, greaterThan(stats),
          reason: 'Chính sách bảo mật phải xuống dưới các mục khác');
      expect(privacy, lessThan(logout),
          reason: 'Chính sách bảo mật phải nằm ngay trên nút Đăng xuất');
    });

    testWidgets('bấm mục Chính sách bảo mật → mở đúng route',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.scrollUntilVisible(find.text('Chính sách bảo mật'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(find.text('Chính sách bảo mật'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ROUTE /profile/privacy'), findsOneWidget);
    });

    testWidgets('bấm nút Lịch Sử trong card ví → mở /profile/wallet',
        (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Lịch Sử'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ROUTE /profile/wallet'), findsOneWidget);
    });

    testWidgets('bấm nút Xem gói → mở /profile/subscription', (tester) async {
      await tester.pumpWidget(_host(overrides, const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Xem gói'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ROUTE /profile/subscription'), findsOneWidget);
    });
  });
}
