import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAdmin => user?.isAdmin ?? false;
  bool get isBrand => user?.isBrand ?? false;
  bool get isCustomer => user?.isCustomer ?? true;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      try {
        final user = await _repository.getCurrentUser();
        state = state.copyWith(isAuthenticated: true, user: user);
      } catch (_) {
        await _repository.logout();
        state = const AuthState(isAuthenticated: false, user: null);
      }
    } else {
      state = const AuthState(isAuthenticated: false, user: null);
    }
  }

  Future<bool> login(String loginName, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final tokenResponse = await _repository.login(LoginRequest(loginName: loginName, password: password));
      if (tokenResponse.accessToken.isEmpty) {
        throw Exception('Sai tài khoản hoặc mật khẩu.');
      }
      final user = await _repository.getCurrentUser();
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
    await _repository.logout();
    state = const AuthState(isAuthenticated: false, user: null);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
