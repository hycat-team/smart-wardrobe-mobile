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
  static bool _isSdkInitialized = false;
  bool _isLocallyLoading = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSdk();
  }

  Future<void> _initGoogleSdk() async {
    // Web dùng luồng redirect của BE (guide §1) — KHÔNG dùng GIS nên không cần
    // khởi tạo SDK Google ở đây.
    if (kIsWeb) return;

    if (!_isSdkInitialized) {
      _isSdkInitialized = true;
      final clientId = AppConstants.googleClientId;
      try {
        await GoogleSignIn.instance.initialize(
          clientId: null,
          serverClientId: clientId.isNotEmpty ? clientId : null,
        );
      } catch (e) {
        debugPrint('Google Sign-In SDK initialization warning: $e');
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleAndroidSignIn() async {
    if (_isLocallyLoading) return;
    final globalLoading = ref.read(authStateProvider).isLoading;
    if (globalLoading) return;

    setState(() => _isLocallyLoading = true);

    try {
      if (!_isSdkInitialized) {
        await _initGoogleSdk();
      }

      final account = await GoogleSignIn.instance.authenticate();
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocallyLoading = false);
      final rawStr = e.toString().toLowerCase();
      if (rawStr.contains('canceled') ||
          rawStr.contains('cancelled') ||
          rawStr.contains('access_denied')) {
        widget.onOutcome?.call(GoogleSignInOutcome.cancelled());
      } else {
        final failedOutcome = GoogleSignInOutcome.failed(
          errorCode: AuthErrorCode.serverError,
          customMessage: 'Đăng nhập Google thất bại: ${e.toString().replaceAll("Exception: ", "")}',
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
      if (isLoading) {
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
      return buildWebGoogleButton();
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
