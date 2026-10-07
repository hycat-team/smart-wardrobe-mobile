import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import 'google_logo.dart';
import 'google_sign_in_bootstrap.dart';
import 'web_button.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  final ValueChanged<GoogleSignInOutcome>? onOutcome;
  final bool isRegister;

  const GoogleSignInButton({
    super.key,
    this.onOutcome,
    this.isRegister = false,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  static bool get _isSdkInitialized => GoogleSignInBootstrap.isInitialized;
  bool _isLocallyLoading = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webAuthSubscription;

  @override
  void initState() {
    super.initState();
    _initGoogleSdk();
  }

  @override
  void dispose() {
    _webAuthSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initGoogleSdk() async {
    // Dùng bootstrap singleton — main.dart đã initialize lúc startup, gọi
    // lại ở đây sẽ làm google_sign_in 7.x ném lỗi trên bản release.
    await GoogleSignInBootstrap.ensureInitialized(AppConstants.googleClientId);
    if (mounted) {
      setState(() {});
    }

    // Web (GIS): lắng nghe sự kiện đăng nhập -> lấy ID token -> đổi Bearer.
    if (kIsWeb) {
      _webAuthSubscription ??=
          GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final idToken = event.user.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty) {
            _exchangeIdToken(idToken);
          }
        }
      });
      // Xoá phiên Google cũ để GIS không tự chọn lại tài khoản trước đó.
      await _clearPreviousGoogleSession();
    }
  }

  /// Xoá phiên Google cục bộ và ngắt kết nối để lần đăng nhập kế tiếp luôn
  /// hiển thị lại account chooser (spec 012 — FR-013). Không ném lỗi nếu chưa có phiên.
  Future<void> _clearPreviousGoogleSession() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      debugPrint('Google Sign-In disconnect warning: $e');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign-In signOut warning: $e');
    }
  }

  Future<void> _handleAndroidSignIn() async {
    if (_isLocallyLoading) return;
    final globalLoading = ref.read(authStateProvider).isLoading;
    if (globalLoading) return;

    setState(() => _isLocallyLoading = true);

    try {
      // Luôn gọi (idempotent) — bootstrap tự bỏ qua nếu đã khởi tạo.
      await _initGoogleSdk();

      // KHÔNG gọi _clearPreviousGoogleSession() trên Android.
      //
      // Lý do: GoogleSignIn.authenticate() chạy *button flow*
      // (GetSignInWithGoogleOption) nên account chooser LUÔN hiện, không phụ
      // thuộc vào việc xoá phiên cục bộ — đây chỉ là workaround cho web
      // (spec 012 FR-013, vì GIS tự chọn lại tài khoản cũ). Ngoài ra
      // disconnect() còn gọi revokeAccess tức thu hồi quyền của user qua
      // mạng, làm chậm thêm mỗi lần bấm nút.
      //
      // Timeout: authenticate() await thẳng CredentialManager.getCredentialAsync
      // và KHÔNG có timeout sẵn. Khi Android OAuth client không khớp
      // (package + SHA-1) thì callback không bao giờ được gọi → nút đứng ở
      // trạng thái loading vĩnh viễn, không báo lỗi, không log. Đây là lý do
      // lỗi "12500 / UNREGISTERED_ON_API_CONSOLE" phải mò tới logcat mới biết.
      // 2 phút: đủ dài để người dùng chọn tài khoản thoải mái, nhưng vẫn bắt
      // được trường hợp treo vĩnh viễn.
      final account = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(minutes: 2));
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (mounted) setState(() => _isLocallyLoading = false);
        final failedOutcome = GoogleSignInOutcome.failed(
          errorCode: AuthErrorCode.invalidToken,
          customMessage: 'Không nhận được mã xác thực Google, vui lòng thử lại.',
        );
        widget.onOutcome?.call(failedOutcome);
        return;
      }

      await _exchangeIdToken(idToken);
    } on TimeoutException {
      // Không dính nhánh cancelled bên dưới: timeout KHÔNG phải người dùng
      // huỷ, nên phải báo lỗi thật chứ không im lặng.
      if (!mounted) return;
      setState(() => _isLocallyLoading = false);
      widget.onOutcome?.call(GoogleSignInOutcome.failed(
        errorCode: AuthErrorCode.serverError,
        customMessage:
            'Google không phản hồi sau 2 phút. Vui lòng thử lại hoặc đăng nhập bằng email.',
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocallyLoading = false);
      final rawStr = e.toString().toLowerCase();
      if (rawStr.contains('canceled') ||
          rawStr.contains('cancelled') ||
          rawStr.contains('access_denied')) {
        widget.onOutcome?.call(GoogleSignInOutcome.cancelled());
      } else if (rawStr.contains('timeout')) {
        widget.onOutcome?.call(GoogleSignInOutcome.failed(
          errorCode: AuthErrorCode.serverError,
          customMessage:
              'Google không phản hồi sau 2 phút. Vui lòng thử lại hoặc đăng nhập bằng email.',
        ));
      } else {
        final failedOutcome = GoogleSignInOutcome.failed(
          errorCode: AuthErrorCode.serverError,
          customMessage:
              'Đăng nhập Google thất bại: ${e.toString().replaceAll("Exception: ", "")}',
        );
        widget.onOutcome?.call(failedOutcome);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocallyLoading = false);
      }
    }
  }

  Future<void> _exchangeIdToken(String idToken) async {
    final outcome = await ref.read(authStateProvider.notifier).loginWithGoogle(
          idToken,
          deviceName: kIsWeb ? 'Web' : 'Android',
        );
    if (!mounted) return;
    widget.onOutcome?.call(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = _isLocallyLoading || authState.isLoading;

    if (kIsWeb) {
      // Chờ GIS sẵn sàng + trạng thái loading.
      if (isLoading || !_isSdkInitialized) {
        return const SizedBox(
          height: 50,
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 320.0;
          return Center(
            child: SizedBox(
              width: w,
              height: 48,
              child: buildWebGoogleButton(width: w),
            ),
          );
        },
      );
    }

    // Quiet Luxury Custom Google Button for Android / Mobile
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : _handleAndroidSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.surface.withOpacity(0.7),
          disabledForegroundColor: AppColors.textSecondary.withOpacity(0.5),
          side: BorderSide(
            color: isLoading
                ? AppColors.border.withOpacity(0.5)
                : const Color(0xFFE5E2DE),
            width: 1.0,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Tiếp tục với Google',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
