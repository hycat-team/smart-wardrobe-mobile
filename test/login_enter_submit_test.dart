import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/presentation/login_screen.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';

/// Ghi lại số lần `login` được gọi, không chạm mạng.
class _RecordingAuthRepository extends AuthRepository {
  int loginCallCount = 0;
  final List<String> logins = <String>[];

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthTokenResponse> login(LoginRequest request) async {
    loginCallCount++;
    logins.add('${request.loginName}|${request.password}');
    throw Exception('Sai tài khoản hoặc mật khẩu');
  }
}

void main() {
  late _RecordingAuthRepository repo;

  setUp(() => repo = _RecordingAuthRepository());

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> fillCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      '123456',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Tap vào ô mật khẩu rồi gửi action "done" như bàn phím thật.
  Future<void> pressEnterOnPassword(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextFormField, 'Mật khẩu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('LoginScreen — phím Enter', () {
    testWidgets('Enter ở ô mật khẩu → gọi đăng nhập', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email hoặc Tên đăng nhập'),
        'user',
      );
      await fillCredentials(tester);

      await pressEnterOnPassword(tester);

      expect(repo.loginCallCount, 1);
    });

    testWidgets('Enter ở ô mật khẩu → truyền đúng tài khoản/mật khẩu',
        (tester) async {
      await pumpLogin(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email hoặc Tên đăng nhập'),
        'user',
      );
      await fillCredentials(tester);

      await pressEnterOnPassword(tester);

      expect(repo.logins, ['user|123456']);
    });

    testWidgets('ô tài khoản dùng action "next" để chuyển ô',
        (tester) async {
      await pumpLogin(tester);

      final username = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email hoặc Tên đăng nhập'),
      );
      final password = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Mật khẩu'),
      );

      expect(username.textInputAction, TextInputAction.next);
      expect(password.textInputAction, TextInputAction.done);
    });

    testWidgets('Enter khi thiếu mật khẩu → validate, không gọi API',
        (tester) async {
      await pumpLogin(tester);

      await pressEnterOnPassword(tester);

      // Form chặn trước khi gọi repository.
      expect(repo.loginCallCount, 0);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });
}
