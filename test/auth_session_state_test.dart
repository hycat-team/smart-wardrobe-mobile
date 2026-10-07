// Spec 015 — Nhóm A: bốn trạng thái phiên.
//
// FR-001 (4 trạng thái) · FR-002 (tắt cờ ở mọi đường thoát) ·
// FR-026/027/028 (lỗi tạm thời giữ phiên, token bị từ chối thì xoá) ·
// FR-035 (không tự thử lại) · FR-003 + SC-011 (splash chỉ lúc khởi động).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wardrobe/features/auth/data/auth_repository.dart';
import 'package:smart_wardrobe/features/auth/models/auth_models.dart';
import 'package:smart_wardrobe/features/auth/providers/auth_provider.dart';

/// DioException mô phỏng lỗi mạng: KHÔNG có `response` (FR-027 — giữ phiên).
DioException _networkError() {
  return DioException(
    requestOptions: RequestOptions(path: '/me'),
    type: DioExceptionType.connectionError,
    error: 'connection refused',
  );
}

/// DioException mô phỏng máy chủ từ chối token (FR-028 — xoá phiên).
DioException _rejected(int status) {
  return DioException(
    requestOptions: RequestOptions(path: '/me'),
    response: Response(
      requestOptions: RequestOptions(path: '/me'),
      statusCode: status,
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _serverError() {
  return DioException(
    requestOptions: RequestOptions(path: '/me'),
    response: Response(
      requestOptions: RequestOptions(path: '/me'),
      statusCode: 503,
    ),
    type: DioExceptionType.badResponse,
  );
}

class _ScriptedAuthRepository extends AuthRepository {
  bool hasToken;
  Object? currentUserError;
  int currentUserCalls = 0;
  int logoutCalls = 0;

  _ScriptedAuthRepository({this.hasToken = true, this.currentUserError});

  @override
  Future<bool> isAuthenticated() async => hasToken;

  @override
  Future<UserModel> getCurrentUser() async {
    currentUserCalls++;
    final err = currentUserError;
    if (err != null) throw err;
    return const UserModel(
      id: 'u1',
      username: 'user',
      email: 'user@smartwardrobe.com',
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    hasToken = false;
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 40));

/// Riverpod lazy: provider chỉ được tạo khi có `read`. Phải chạm vào notifier
/// TRƯỚC khi chờ, nếu không `checkAuthStatus()` chưa bao giờ chạy.
///
/// **Bắt buộc** phải `await` hàm này (hoặc tương đương) trước khi container bị
/// dispose. Nếu teardown xảy ra khi `checkAuthStatus()` còn đang chạy, notifier sẽ
/// bị dispose rồi mới set state → unhandled async error làm hỏng cả test runner.
Future<void> _boot(ProviderContainer container) async {
  container.read(authStateProvider.notifier);
  await _settle();
}

void main() {
  // AuthStartup là singleton cấp thư viện — mỗi test phải reset để lần kiểm tra
  // đầu tiên luôn được coi là "khởi động ứng dụng".
  setUp(AuthStartup.debugReset);

  group('AuthState — mặc định và bốn trạng thái (FR-001)', () {
    test('mặc định: isCheckingAuth = true, authCheckFailed = false', () {
      const s = AuthState();
      expect(s.isCheckingAuth, isTrue);
      expect(s.authCheckFailed, isFalse);
      expect(s.isAuthenticated, isFalse);
    });

    test('isShowingSplash đúng ở trạng thái ① và ③', () {
      expect(const AuthState().isShowingSplash, isTrue);
      expect(const AuthState(authCheckFailed: true).isShowingSplash, isTrue);
      expect(
        const AuthState(isCheckingAuth: false).isShowingSplash,
        isFalse,
      );
    });

    test('copyWith tắt được authCheckFailed', () {
      const s = AuthState(authCheckFailed: true);
      expect(s.copyWith(clearAuthCheckFailed: true).authCheckFailed, isFalse);
    });
  });

  group('AuthNotifier — 4 trạng thái', () {
    test('② không có token → ④ chưa đăng nhập, tắt cờ kiểm tra', () async {
      final repo = _ScriptedAuthRepository(hasToken: false);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.isCheckingAuth, isFalse, reason: 'FR-002 phải tắt cờ');
      expect(s.authCheckFailed, isFalse);
      expect(s.isAuthenticated, isFalse);
      expect(s.isShowingSplash, isFalse);
    });

    test('token hợp lệ → ② đã đăng nhập, có hồ sơ', () async {
      final repo = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.isCheckingAuth, isFalse);
      expect(s.authCheckFailed, isFalse);
      expect(s.isAuthenticated, isTrue);
      expect(s.user?.username, 'user');
      expect(s.isShowingSplash, isFalse);
    });

    test('lỗi mạng (không có response) → ③ giữ phiên, authCheckFailed = true',
        () async {
      final repo = _ScriptedAuthRepository(currentUserError: _networkError());
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.authCheckFailed, isTrue, reason: 'FR-027 phải giữ phiên');
      expect(s.isAuthenticated, isTrue);
      expect(s.isCheckingAuth, isFalse);
      expect(
        repo.logoutCalls,
        0,
        reason: 'lỗi mạng KHÔNG được xoá phiên',
      );
      expect(s.isShowingSplash, isTrue, reason: 'vẫn ở lại splash');
      expect(s.errorMessage, isNotNull);
    });

    test('lỗi 5xx → ③ giữ phiên, không xoá', () async {
      final repo = _ScriptedAuthRepository(currentUserError: _serverError());
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.authCheckFailed, isTrue);
      expect(s.isAuthenticated, isTrue);
      expect(repo.logoutCalls, 0);
    });

    test('401 → ④ xoá phiên, KHÔNG vào ③', () async {
      final repo = _ScriptedAuthRepository(currentUserError: _rejected(401));
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.isAuthenticated, isFalse);
      expect(s.authCheckFailed, isFalse);
      expect(s.isShowingSplash, isFalse);
      expect(repo.logoutCalls, 1, reason: 'FR-028 phải xoá phiên');
    });

    test('403 cũng được coi là token bị từ chối', () async {
      final repo = _ScriptedAuthRepository(currentUserError: _rejected(403));
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.isAuthenticated, isFalse);
      expect(repo.logoutCalls, 1);
    });

    test('lỗi không phải DioException → ③ giữ phiên + không vô hạn', () async {
      final repo =
          _ScriptedAuthRepository(currentUserError: StateError('hỏng bất ngờ'));
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final s = container.read(authStateProvider);

      expect(s.authCheckFailed, isTrue);
      expect(s.isCheckingAuth, isFalse, reason: 'FR-002 không được kẹt');
    });
  });

  group('Không tự thử lại (FR-035)', () {
    test('sau khi rơi vào ③, không có lời gọi getCurrentUser nào phát sinh',
        () async {
      final repo = _ScriptedAuthRepository(currentUserError: _networkError());
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final afterFirstCheck = repo.currentUserCalls;

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(
        repo.currentUserCalls,
        afterFirstCheck,
        reason: 'không được có timer hay vòng lặp tự thử lại',
      );
    });

    test('bấm "Thử lại" mới tạo ra lời gọi mới', () async {
      final repo = _ScriptedAuthRepository(currentUserError: _networkError());
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final before = repo.currentUserCalls;

      container.read(authStateProvider.notifier).checkAuthStatus();
      await _boot(container);

      expect(repo.currentUserCalls, before + 1);
    });
  });

  group('Chặn gọi chồng', () {
    test('gọi checkAuthStatus hai lần liên tiếp chỉ tạo một lời gọi',
        () async {
      final repo = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      final before = repo.currentUserCalls;

      final notifier = container.read(authStateProvider.notifier);
      notifier.checkAuthStatus();
      notifier.checkAuthStatus();
      await _boot(container);

      expect(repo.currentUserCalls, before + 1);
    });

    test('thử lại khi máy chủ từ chối token → sang ④, không quay lại ③',
        () async {
      final repo = _ScriptedAuthRepository(currentUserError: _networkError());
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _boot(container);
      expect(container.read(authStateProvider).authCheckFailed, isTrue);

      // Lần thử lại này máy chủ trả 401.
      repo.currentUserError = _rejected(401);
      container.read(authStateProvider.notifier).checkAuthStatus();
      await _boot(container);

      final s = container.read(authStateProvider);
      expect(s.authCheckFailed, isFalse);
      expect(s.isAuthenticated, isFalse);
    });
  });

  group('Splash chỉ hiện khi khởi động (FR-003, SC-011)', () {
    test('lần kiểm tra đầu tiên bắt đầu với isCheckingAuth = true', () async {
      expect(AuthStartup.hasBootstrapped, isFalse);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_ScriptedAuthRepository(hasToken: false)),
        ],
      );
      addTearDown(container.dispose);

      // Đọc ngay lập tức, trước khi I/O hoàn tất.
      expect(container.read(authStateProvider).isCheckingAuth, isTrue);

      // Để I/O hoàn tất trước khi container bị dispose.
      await _boot(container);
    });

    test('lần thứ hai (đổi phiên) bắt đầu với isCheckingAuth = false — không nháy splash',
        () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_ScriptedAuthRepository(hasToken: false)),
        ],
      );
      // Đọc NGAY khi provider vừa được tạo — lúc này kiểm tra phiên đang chạy.
      container.read(authStateProvider.notifier);
      expect(container.read(authStateProvider).isCheckingAuth, isTrue);
      await _settle();

      expect(AuthStartup.hasBootstrapped, isTrue);
      container.dispose();

      // Provider mô phỏng lại việc main.dart đổi ValueKey của ProviderScope.
      final container2 = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_ScriptedAuthRepository(hasToken: false)),
        ],
      );
      addTearDown(container2.dispose);

      container2.read(authStateProvider.notifier);
      expect(
        container2.read(authStateProvider).isCheckingAuth,
        isFalse,
        reason: 'SC-011: đổi tài khoản không được nháy splash',
      );

      await _settle();
    });
  });

  group('Cờ splash lúc khởi động (FR-003, FR-005, SC-002)', () {
    test('mới chạy ứng dụng thì splash còn phải hiện', () {
      expect(AuthStartup.isBootSplashPending, isTrue,
          reason: 'SC-002: 100% lần mở app đều phải thấy splash');
    });

    test('splash hiện xong thì không hiện lại, kể cả khi đổi tài khoản', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_ScriptedAuthRepository(hasToken: false)),
        ],
      );
      addTearDown(container.dispose);
      container.read(authStateProvider.notifier);
      await _boot(container);

      // Màn hình khởi động tự đánh dấu đã hiện xong.
      AuthStartup.markBootSplashDone();
      expect(AuthStartup.isBootSplashPending, isFalse);

      // ProviderScope bị recreate khi đổi tài khoản: cờ nằm ở singleton nên
      // KHÔNG quay lại trạng thái chờ — nếu không, logout sẽ nháy splash.
      final container2 = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_ScriptedAuthRepository(hasToken: false)),
        ],
      );
      addTearDown(container2.dispose);
      container2.read(authStateProvider.notifier);
      await _settle();

      expect(AuthStartup.isBootSplashPending, isFalse);
    });

    test('debugReset đưa cả hai cờ về trạng thái ban đầu', () {
      AuthStartup.shouldShowSplashOnNextCheck();
      AuthStartup.markBootSplashDone();

      AuthStartup.debugReset();

      expect(AuthStartup.hasBootstrapped, isFalse);
      expect(AuthStartup.isBootSplashPending, isTrue);
    });
  });
}
