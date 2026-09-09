import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';

class RealHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = RealHttpOverrides();

  group('Auth Integration Tests', () {
    final repo = AuthRepository();

    test('Login with wrong credentials fails with exact backend error message', () async {
      try {
        await repo.login(
          const LoginRequest(loginName: 'user', password: 'wrongpassword'),
        );
        fail('Should throw exception on wrong password');
      } catch (e) {
        print('Wrong login caught error: $e');
        expect(e.toString(), contains('Sai tài khoản hoặc mật khẩu'));
      }
    });

    test('Login with user/123456 succeeds and retrieves profile', () async {
      final res = await repo.login(
        const LoginRequest(loginName: 'user', password: '123456'),
      );
      print('Valid login token: ${res.accessToken.substring(0, 25)}...');
      expect(res.accessToken.isNotEmpty, true);
      expect(res.accessToken.split('.').length, 3);

      final user = await repo.getCurrentUser();
      print('Current user profile: ${user.username} (${user.email})');
      expect(user.username, 'user');
      expect(user.email, 'user@smartwardrobe.com');
    });
  });
}
