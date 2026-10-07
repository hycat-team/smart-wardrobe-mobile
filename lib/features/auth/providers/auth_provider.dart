import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_provider.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;

  /// Spec 015 — 4 trạng thái phiên (FR-001).
  ///
  /// ① `isCheckingAuth = true`  → đang kiểm tra phiên.
  /// ② `isAuthenticated = true, authCheckFailed = false` → đã đăng nhập, có hồ sơ.
  /// ③ `authCheckFailed = true` → lỗi tạm thời (mạng / máy chủ), token **chưa**
  ///    bị từ chối nên **giữ phiên**; người dùng ở lại màn hình khởi động chờ
  ///    bấm "Thử lại" (FR-027).
  /// ④ Không token, hoặc token bị từ chối → màn đăng nhập.
  ///
  /// `isCheckingAuth` mặc định `true` để splash hiện ngay khi khởi động.
  final bool isCheckingAuth;
  final bool authCheckFailed;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.isCheckingAuth = true,
    this.authCheckFailed = false,
  });

  bool get isAdmin => user?.isAdmin ?? false;
  bool get isBrand => user?.isBrand ?? false;
  bool get isCustomer => user?.isCustomer ?? true;

  /// Còn đang ở màn hình khởi động: đang kiểm tra, hoặc đang chờ thử lại (③).
  /// Nhóm A yêu cầu chặn cả hai — chỉ kiểm `isCheckingAuth` là không đủ vì sau
  /// lỗi tạm thời cờ đó đã tắt nhưng người dùng vẫn phải ở lại splash.
  bool get isShowingSplash => isCheckingAuth || authCheckFailed;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
    String? successMessage,
    bool? isCheckingAuth,
    bool? authCheckFailed,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAuthCheckFailed = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      authCheckFailed: clearAuthCheckFailed
          ? false
          : (authCheckFailed ?? this.authCheckFailed),
    );
  }
}

/// Đánh dấu ứng dụng đã khởi động (spec 015 — FR-003, SC-011).
///
/// Vì sao phải nằm ở cấp thư viện (static) mà không đặt trong một provider:
/// `logout()` và chuyển tài khoản Google đều tăng `sessionProvider`, khiến
/// `main.dart` đổi `ValueKey` của `ProviderScope` → **mọi provider bị dispose và tạo
/// lại**. Nếu cờ này nằm trong provider thì nó bị xoá đúng lúc cần dùng, và splash sẽ
/// nháy giữa phiên mỗi lần đổi tài khoản — đúng thứ FR-003 cấm.
///
/// Lần kiểm tra phiên **đầu tiên** của tiến trình bắt đầu với `isCheckingAuth = true`
/// (splash hiện). Từ lần thứ hai trở đi bắt đầu với `false` để chuyển thẳng sang màn
/// đăng nhập, không nháy splash.
class AuthStartup {
  AuthStartup._();

  static bool _hasBootstrapped = false;

  /// Đã hiển thị màn hình khởi động của tiến trình này hay chưa (FR-003).
  ///
  /// Tách khỏi [_hasBootstrapped] vì hai việc khác nhau: cờ này bị màn hình khởi
  /// động **tự tắt** sau khi hiện, trong khi [_hasBootstrapped] bị chính lần kiểm
  /// phiên đầu tiên đánh dấu. Nếu dùng chung một cờ thì hoặc splash không hiện,
  /// hoặc hiện lại mỗi lần đổi tài khoản — đều sai.
  static bool _bootSplashDone = false;

  static bool get hasBootstrapped => _hasBootstrapped;

  /// `true` khi màn hình khởi động của tiến trình chưa được hiển thị lần nào.
  ///
  /// Nhờ vậy `ProviderScope` bị recreate khi đổi tài khoản (logout / sang user
  /// khác) sẽ **không** hiện splash lần nữa — FR-003 cấm nháy giữa phiên.
  static bool get isBootSplashPending => !_bootSplashDone;

  /// Màn hình khởi động đã hiển thị xong, không cần hiện lại trong tiến trình này.
  static void markBootSplashDone() => _bootSplashDone = true;

  /// Trả `true` nếu đây là lần kiểm tra phiên đầu tiên → nên hiện splash.
  static bool shouldShowSplashOnNextCheck() {
    if (_hasBootstrapped) return false;
    _hasBootstrapped = true;
    return true;
  }

  /// Chỉ dùng cho test — đặt lại trạng thái singleton.
  @visibleForTesting
  static void debugReset() {
    _hasBootstrapped = false;
    _bootSplashDone = false;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  bool _isLoggingOut = false;

  /// Chặn gọi chồng: bấm "Thử lại" liên tục không được tạo ra loạt yêu cầu
  /// dồn dập (spec 015 — T009, FR-035).
  ///
  /// Dùng **single-flight** thay vì cờ boolean: lời gọi chồng nhận lại đúng
  /// Future đang chạy nên vẫn `await` được kết quả thật, thay vì trả về ngay
  /// và làm người gọi đọc state quá sớm.
  Future<void>? _checkAuthInFlight;

  AuthNotifier(this._repository, this._ref)
      : super(
          AuthState(
            // Chỉ lần kiểm tra phiên ĐẦU TIÊN của tiến trình mới bắt đầu ở
            // trạng thái ① (hiện splash). Từ lần thứ hai — tức do đổi phiên —
            // bắt đầu ở `false` để chuyển thẳng sang màn đăng nhập, không nháy
            // splash (FR-003, SC-011).
            isCheckingAuth: !AuthStartup.hasBootstrapped,
          ),
        ) {
    _setupForcedLogout();
    checkAuthStatus();
  }

  void _setupForcedLogout() {
    ApiClient.onGlobalForcedLogout = () {
      logout();
    };
  }

  /// Kiểm tra phiên theo **bốn nhánh** (spec 015 — FR-001, FR-027, FR-028).
  ///
  /// Giữ **không có tham số** để các fake notifier trong test sẵn có không phải
  /// đổi chữ ký override.
  ///
  /// Splash phải hiện khi: đây là lần kiểm tra phiên đầu tiên của tiến trình, hoặc
  /// đang thử lại từ trạng thái ③. Ở các trường hợp khác (đổi phiên giữa phiên) thì
  /// **không** hiện splash — chuyển thẳng sang màn đăng nhập (FR-003, SC-011).
  ///
  /// **Không** có timer hay vòng lặp tự thử lại (FR-035). Chỉ lời gọi tường minh từ
  /// nút "Thử lại" mới được phát sinh yêu cầu.
  Future<void> checkAuthStatus() {
    final existing = _checkAuthInFlight;
    if (existing != null) return existing;

    final future = _runCheckAuthStatus();
    _checkAuthInFlight = future;
    return future.whenComplete(() {
      if (identical(_checkAuthInFlight, future)) {
        _checkAuthInFlight = null;
      }
    });
  }

  Future<void> _runCheckAuthStatus() async {
    final showSplash =
        AuthStartup.shouldShowSplashOnNextCheck() || state.authCheckFailed;

    if (showSplash) {
      state = state.copyWith(isCheckingAuth: true, clearAuthCheckFailed: true);
    }

    try {
      final hasToken = await _repository.isAuthenticated();

      if (!hasToken) {
        // ④ Không có token → màn đăng nhập.
        state = state.copyWith(
          isCheckingAuth: false,
          clearAuthCheckFailed: true,
          isAuthenticated: false,
          user: null,
        );
        return;
      }

      try {
        final user = await _repository.getCurrentUser();
        // ② Đăng nhập thành công.
        state = state.copyWith(
          isCheckingAuth: false,
          clearAuthCheckFailed: true,
          isAuthenticated: true,
          user: user,
          clearError: true,
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          // ④ Token bị từ chối → xoá phiên, về màn đăng nhập.
          await _repository.logout();
          state = state.copyWith(
            isCheckingAuth: false,
            clearAuthCheckFailed: true,
            isAuthenticated: false,
            user: null,
            errorMessage: e.toString().replaceAll('Exception: ', ''),
          );
        } else {
          // ③ Lỗi tạm thời: mất mạng, timeout, hoặc 5xx → GIỮ PHIÊN (FR-027).
          state = state.copyWith(
            isCheckingAuth: false,
            authCheckFailed: true,
            isAuthenticated: true,
            errorMessage: _transientErrorMessage(e),
          );
        }
      } catch (e) {
        // Không phải DioException: ③ lỗi tạm thời + ghi log (không đoán).
        debugPrint('[AuthNotifier] checkAuthStatus transient error: $e');
        state = state.copyWith(
          isCheckingAuth: false,
          authCheckFailed: true,
          isAuthenticated: true,
          errorMessage: 'Không tải được thông tin người dùng. Vui lòng thử lại.',
        );
      }
    } finally {
      // FR-002: tắt cờ "đang kiểm tra" ở MỌI đường thoát, kể cả khi throw —
      // nếu không, một lỗi bất ngờ sẽ kẹt người dùng ở splash vĩnh viễn.
      if (state.isCheckingAuth) {
        state = state.copyWith(isCheckingAuth: false);
      }
    }
  }

  String _transientErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại.';
    }
    final code = e.response?.statusCode;
    if (code != null && code >= 500) {
      return 'Máy chủ đang bận. Vui lòng thử lại sau.';
    }
    return 'Không tải được thông tin người dùng. Vui lòng thử lại.';
  }

  Future<bool> login(String loginName, String password) async {
    if (state.isAuthenticated) {
      await _repository.logout();
      bumpAppSession();
      _ref.read(sessionProvider.notifier).state++;
      state = const AuthState();
    }
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final tokenResponse = await _repository.login(LoginRequest(loginName: loginName, password: password));
      if (tokenResponse.accessToken.isEmpty) {
        throw Exception('Sai tài khoản hoặc mật khẩu.');
      }
      final user = await _repository.getCurrentUser();
      PaintingBinding.instance.imageCache.clear();
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      await _repository.logout();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<GoogleSignInOutcome> loginWithGoogle(String idToken, {String? deviceName}) async {
    // Xoá phiên cũ (token + state) TRƯỚC khi đăng nhập để mỗi tài khoản Google
    // vào đúng tài khoản Closy, không kế thừa state/dữ liệu tài khoản trước
    // (spec 012 — FR-012, FR-013).
    if (state.isAuthenticated) {
      await _repository.logout();
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      bumpAppSession();
      _ref.read(sessionProvider.notifier).state++;
      state = const AuthState();
    }
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final outcome = await _repository.loginWithGoogle(idToken, deviceName: deviceName);
      if (outcome.success) {
        final user = await _repository.getCurrentUser();
        PaintingBinding.instance.imageCache.clear();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          successMessage: outcome.message,
        );
        return outcome;
      } else {
        final isCancelled = outcome.errorCode == AuthErrorCode.cancelled;
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          errorMessage: isCancelled ? null : outcome.message,
        );
        return outcome;
      }
    } catch (e) {
      await _repository.logout();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return GoogleSignInOutcome.failed(
        errorCode: AuthErrorCode.serverError,
        customMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Web: hoàn tất đăng nhập Google sau khi BE redirect về `/auth/callback`.
  /// BE đã đặt cookie HttpOnly; xác nhận qua `/me` rồi vào trạng thái đã
  /// đăng nhập.
  Future<bool> completeWebGoogleLogin() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final user = await _repository.completeWebSession();
      PaintingBinding.instance.imageCache.clear();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        successMessage: 'Đăng nhập Google thành công!',
      );
      return true;
    } catch (e) {
      await _repository.logout();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.register(request);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Mã OTP đã được gửi đến email của bạn.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> confirmRegisterOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.confirmRegisterOtp(email, otpCode);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Xác thực tài khoản thành công! Bạn có thể thiết lập gu thời trang.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resendRegisterOtp(String email) async {
    try {
      await _repository.resendRegisterOtp(email);
      state = state.copyWith(successMessage: 'Đã gửi lại mã OTP mới.');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Mã xác thực khôi phục mật khẩu đã được gửi về email.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> confirmForgotPasswordOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.confirmForgotPasswordOtp(email, otpCode);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Mã OTP hợp lệ. Vui lòng nhập mật khẩu mới.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword, String confirmPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.resetPassword(newPassword, confirmPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> savePreferences(List<String> styles, String palette) async {
    await _repository.saveStylePreferences(styles, palette);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await _repository.logout();
      // Ngắt kết nối và xoá phiên Google để lần đăng nhập kế tiếp luôn
      // hiển thị lại Account Chooser cho phép chọn tài khoản Google khác.
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      // Xóa cache ảnh trong RAM để avatar/ảnh của A không lóe lên ở B.
      PaintingBinding.instance.imageCache.clear();
      state = const AuthState(isAuthenticated: false, user: null);
      bumpAppSession();
      _ref.read(sessionProvider.notifier).state++;
    } finally {
      _isLoggingOut = false;
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});
