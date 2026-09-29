import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:smart_wardrobe/core/network/api_client.dart';
import 'package:smart_wardrobe/core/constants/app_constants.dart';
import 'package:smart_wardrobe/core/storage/secure_storage_service.dart';
import 'package:smart_wardrobe/core/session/session_provider.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';

class MockAuthRepository extends AuthRepository {
  bool isAuth = false;
  UserModel? mockUser;
  GoogleSignInOutcome? mockOutcome;
  int logoutCallCount = 0;

  @override
  Future<bool> isAuthenticated() async => isAuth;

  @override
  Future<UserModel> getCurrentUser() async {
    if (mockUser != null) return mockUser!;
    throw Exception('No user');
  }

  @override
  Future<GoogleSignInOutcome> loginWithGoogle(String idToken, {String? deviceName}) async {
    return mockOutcome ?? GoogleSignInOutcome.succeeded();
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    isAuth = false;
  }
}

void main() {
  group('Google Auth Models & Error Mapping Tests', () {
    test('User cancellation maps to AuthErrorCode.cancelled without heavy error message', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'access_denied',
        message: 'Người dùng huỷ',
      );
      expect(code, AuthErrorCode.cancelled);

      final outcome = GoogleSignInOutcome.cancelled();
      expect(outcome.success, false);
      expect(outcome.errorCode, AuthErrorCode.cancelled);
      expect(outcome.message, isNull);
    });

    test('400 email_unverified maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'email_unverified',
        statusCode: 400,
        message: 'Email Google chưa được xác thực.',
      );
      expect(code, AuthErrorCode.emailUnverified);
      expect(code.defaultMessage, 'Email Google chưa được xác thực.');
    });

    test('400 email_registered maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'email_registered',
        statusCode: 400,
        message: 'Email đã được đăng ký. Vui lòng đăng nhập bằng mật khẩu.',
      );
      expect(code, AuthErrorCode.emailRegistered);
      expect(code.defaultMessage, contains('Vui lòng đăng nhập bằng mật khẩu'));
    });

    test('409 account_linked maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'account_linked',
        statusCode: 409,
        message: 'Email đã liên kết với tài khoản Google khác.',
      );
      expect(code, AuthErrorCode.accountLinked);
      expect(code.defaultMessage, 'Email đã liên kết với tài khoản Google khác.');
    });

    test('403 account_disabled maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'account_disabled',
        statusCode: 403,
        message: 'Tài khoản đã bị khoá.',
      );
      expect(code, AuthErrorCode.accountDisabled);
      expect(code.defaultMessage, contains('liên hệ CSKH'));
    });

    test('400 exchange_failed maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'exchange_failed',
        statusCode: 400,
      );
      expect(code, AuthErrorCode.exchangeFailed);
      expect(code.defaultMessage, 'Không hoàn tất được đăng nhập, vui lòng thử lại.');
    });

    test('400 invalid_token maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'invalid_token',
        statusCode: 400,
        message: 'Phiên Google không hợp lệ',
      );
      expect(code, AuthErrorCode.invalidToken);
      expect(code.defaultMessage, 'Phiên Google không hợp lệ, thử đăng nhập lại.');
    });

    test('500 server_error maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: 'server_error',
        statusCode: 500,
      );
      expect(code, AuthErrorCode.serverError);
      expect(code.defaultMessage, 'Có lỗi xảy ra, vui lòng thử lại sau.');
    });

    test('Network error maps correctly', () {
      final code = AuthErrorCode.fromErrorAndStatus(
        rawError: null,
        statusCode: null,
        message: 'Connection refused',
      );
      expect(code, AuthErrorCode.network);
      expect(code.defaultMessage, 'Không thể kết nối đến máy chủ.');
    });

    test('GoogleSignInOutcome handles auto-linking properly', () {
      final outcome = GoogleSignInOutcome.succeeded(
        linkedExistingAccount: true,
        message: 'Tài khoản Google đã được liên kết thành công.',
      );
      expect(outcome.success, true);
      expect(outcome.linkedExistingAccount, true);
      expect(outcome.message, 'Tài khoản Google đã được liên kết thành công.');
    });

    test('GoogleLoginRequest and RefreshTokenRequest serialize correctly', () {
      const loginReq = GoogleLoginRequest(idToken: 'mock-id-token', deviceName: 'Android');
      expect(loginReq.toJson(), {
        'idToken': 'mock-id-token',
        'deviceName': 'Android',
      });

      const refreshReq = RefreshTokenRequest(oldRefreshToken: 'mock-refresh-token', deviceName: 'Web');
      expect(refreshReq.toJson(), {
        'oldRefreshToken': 'mock-refresh-token',
        'deviceName': 'Web',
      });
    });
  });

  group('AuthNotifier & Google Login Lifecycle Tests', () {
    test('Cancellation (FR-008) sets no errorMessage in AuthState', () async {
      final mockRepo = MockAuthRepository();
      mockRepo.mockOutcome = GoogleSignInOutcome.cancelled();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      final outcome = await notifier.loginWithGoogle('mock-id-token');

      expect(outcome.success, false);
      expect(outcome.errorCode, AuthErrorCode.cancelled);
      expect(container.read(authStateProvider).errorMessage, isNull);
      expect(container.read(authStateProvider).isAuthenticated, false);
    });

    test('Error outcome (FR-007) sets clear errorMessage in AuthState', () async {
      final mockRepo = MockAuthRepository();
      mockRepo.mockOutcome = GoogleSignInOutcome.failed(
        errorCode: AuthErrorCode.accountDisabled,
        customMessage: 'Tài khoản đã bị khoá. Vui lòng liên hệ CSKH.',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      final outcome = await notifier.loginWithGoogle('mock-id-token');

      expect(outcome.success, false);
      expect(outcome.errorCode, AuthErrorCode.accountDisabled);
      expect(
        container.read(authStateProvider).errorMessage,
        'Tài khoản đã bị khoá. Vui lòng liên hệ CSKH.',
      );
    });

    test('Successful Google login sets isAuthenticated and populates user (US1)', () async {
      final mockRepo = MockAuthRepository();
      mockRepo.mockOutcome = GoogleSignInOutcome.succeeded();
      mockRepo.mockUser = const UserModel(
        id: '123',
        username: 'google_user',
        email: 'google@user.com',
        firstName: 'Google',
        lastName: 'User',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      final outcome = await notifier.loginWithGoogle('mock-id-token');

      expect(outcome.success, true);
      expect(container.read(authStateProvider).isAuthenticated, true);
      expect(container.read(authStateProvider).user?.username, 'google_user');
      expect(container.read(authStateProvider).user?.email, 'google@user.com');
    });

    test('Session restoration (SC-005, QS-007) recovers user session without re-prompt', () async {
      final mockRepo = MockAuthRepository();
      mockRepo.isAuth = true;
      mockRepo.mockUser = const UserModel(
        id: '456',
        username: 'restored_user',
        email: 'restored@user.com',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.checkAuthStatus();

      expect(container.read(authStateProvider).isAuthenticated, true);
      expect(container.read(authStateProvider).user?.username, 'restored_user');
    });
  });

  group('GoogleSignInButton Widget Tests', () {
    testWidgets('Renders "Tiếp tục với Google" and is enabled by default', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Tiếp tục với Google'), findsOneWidget);

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Shows loading indicator and disables button when loading (FR-012)', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            authStateProvider.overrideWith(
              (ref) => _LoadingAuthNotifier(mockRepo, ref),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('ApiClient 401 Interceptor & Refresh Single-Flight Tests (US3)', () {
    setUp(() {
      ApiClient.resetGlobalState();
    });

    tearDown(() {
      ApiClient.resetGlobalState();
    });

    test('401 triggers onForcedLogout when refresh fails (empty refresh token)', () async {
      bool forcedLogoutTriggered = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      dio.httpClientAdapter = Mock401Adapter(statusCode: 401);
      final mockStorage = MockSecureStorage();

      final client = ApiClient(dioClient: dio, storageService: mockStorage);
      client.onForcedLogout = () {
        forcedLogoutTriggered = true;
      };

      try {
        await dio.get('/me');
      } catch (_) {}

      expect(forcedLogoutTriggered, true);
    });

    test('401 on /auth/login does NOT trigger token refresh or forced logout', () async {
      bool forcedLogoutTriggered = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      dio.httpClientAdapter = Mock401Adapter(statusCode: 401);
      final mockStorage = MockSecureStorage();

      final client = ApiClient(dioClient: dio, storageService: mockStorage);
      client.onForcedLogout = () {
        forcedLogoutTriggered = true;
      };

      try {
        await dio.post('/auth/login');
      } catch (_) {}

      expect(forcedLogoutTriggered, false);
    });
  });

  group('Web redirect & callback (010-google-login)', () {
    test('googleWebRedirectUrl builds .../auth/google?redirectUrl=<encoded return>', () {
      const returnUrl = 'http://localhost:8081/auth/callback';
      final url = AppConstants.googleWebRedirectUrl(returnUrl);
      expect(url.contains('/auth/google?redirectUrl='), true);
      expect(url.endsWith(Uri.encodeComponent(returnUrl)), true);
    });

    test('?error= query codes map to AuthErrorCode', () {
      expect(
        AuthErrorCode.fromErrorAndStatus(rawError: 'access_denied'),
        AuthErrorCode.cancelled,
      );
      expect(
        AuthErrorCode.fromErrorAndStatus(rawError: 'email_unverified'),
        AuthErrorCode.emailUnverified,
      );
      expect(
        AuthErrorCode.fromErrorAndStatus(rawError: 'account_linked'),
        AuthErrorCode.accountLinked,
      );
    });

    test('cancelled message is non-heavy (FR-008)', () {
      final msg = AuthErrorCode.cancelled.defaultMessage;
      expect(msg.isNotEmpty, true);
      expect(msg.toLowerCase().contains('huỷ'), true);
    });
  });

  group('US5 - Google multi-account (012)', () {
    test(
        'đăng nhập Google B khi đang ở tài khoản A -> clear phiên cũ, user = B',
        () async {
      final mockRepo = MockAuthRepository()
        ..isAuth = true
        ..mockUser = const UserModel(
          id: '1',
          username: 'user_a',
          email: 'a@x.com',
        );
      mockRepo.mockOutcome = GoogleSignInOutcome.succeeded();

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.checkAuthStatus();
      expect(container.read(authStateProvider).user?.username, 'user_a');

      final sessionBefore = container.read(sessionProvider);

      mockRepo.mockUser = const UserModel(
        id: '2',
        username: 'user_b',
        email: 'b@x.com',
      );
      final outcome = await notifier.loginWithGoogle('token-b');

      expect(outcome.success, true);
      expect(container.read(authStateProvider).isAuthenticated, true);
      expect(container.read(authStateProvider).user?.username, 'user_b');
      expect(mockRepo.logoutCallCount, greaterThanOrEqualTo(1));
      expect(container.read(sessionProvider), sessionBefore + 1);
    });

    test('đăng nhập Google khi chưa có phiên -> không gọi logout', () async {
      final mockRepo = MockAuthRepository()
        ..mockUser = const UserModel(
          id: '3',
          username: 'fresh',
          email: 'f@x.com',
        );
      mockRepo.mockOutcome = GoogleSignInOutcome.succeeded();

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.loginWithGoogle('token-f');

      expect(mockRepo.logoutCallCount, 0);
      expect(container.read(authStateProvider).user?.username, 'fresh');
    });
  });
}

class _LoadingAuthNotifier extends AuthNotifier {
  _LoadingAuthNotifier(super.repo, super.ref) {
    state = const AuthState(isLoading: true);
  }

  @override
  Future<void> checkAuthStatus() async {
    state = const AuthState(isLoading: true);
  }
}

class MockSecureStorage extends SecureStorageService {
  String? token;
  String? refreshToken;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String t) async => token = t;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveRefreshToken(String rt) async => refreshToken = rt;

  @override
  Future<void> clearAll() async {
    token = null;
    refreshToken = null;
  }
}

class Mock401Adapter implements HttpClientAdapter {
  final int statusCode;
  Mock401Adapter({this.statusCode = 401});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message": "Unauthorized"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
