import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';
import 'package:smart_wardrobe/features/profile/data/profile_repository.dart';
import 'package:smart_wardrobe/features/profile/models/user_profile_models.dart';
import 'package:smart_wardrobe/features/profile/presentation/wallet_detail_screen.dart';
import 'package:smart_wardrobe/features/profile/providers/profile_provider.dart';
import 'package:dio/dio.dart';

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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.repo, super.ref) {
    state = const AuthState(isAuthenticated: true);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

/// Wallet cố định để test phần hiển thị, không gọi mạng.
class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(super.repo, super.ref) {
    state = const WalletState(
      wallet: WalletModel(userId: 'me-1', balance: 125000, currency: 'VND'),
    );
  }

  @override
  Future<void> loadWallet() async {}
}

void main() {
  final authRepo = _NoopAuthRepository();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_NoopProfileRepository()),
          authRepositoryProvider.overrideWithValue(authRepo),
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(authRepo, ref)),
          walletProvider.overrideWith((ref) => _FakeWalletNotifier(_NoopProfileRepository(), ref)),
          walletStatementsProvider.overrideWith((ref) async => const <WalletStatementModel>[]),
        ],
        child: const MaterialApp(home: WalletDetailScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Số dư mặc định được ẩn, bấm con mắt mới hiện', (tester) async {
    await pump(tester);

    // Mặc định ẩn: không lộ con số số dư.
    expect(find.text('125.000 đ'), findsNothing);
    expect(find.text('•••••••• đ'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

    // Bấm con mắt -> hiện số dư.
    await tester.tap(find.byIcon(Icons.visibility_off_rounded));
    await tester.pump();

    expect(find.text('125.000 đ'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('Nút nạp ví gọn gàng, không kèm hướng dẫn dài', (tester) async {
    await pump(tester);

    expect(find.text('Nạp ví trên web'), findsOneWidget);
    // Không còn khối hướng dẫn 3 bước cũ.
    expect(find.textContaining('Bước 1'), findsNothing);
    expect(find.textContaining('Bước 2'), findsNothing);
  });
}
