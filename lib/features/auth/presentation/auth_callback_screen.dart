import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

/// Màn hứng callback sau khi BE redirect về từ Google (luồng web — guide §1).
/// Xác nhận phiên qua `GET /me` (cookie HttpOnly do BE đặt) rồi vào app.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  String? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    if (_started) return;
    _started = true;

    final params = Uri.base.queryParameters;

    // BE redirect về kèm `?error=` khi thất bại (guide §4).
    final errorParam = params['error'];
    if (errorParam != null && errorParam.trim().isNotEmpty) {
      final code = AuthErrorCode.fromErrorAndStatus(rawError: errorParam);
      // Huỷ (FR-008): KHÔNG hiển thị lỗi nặng, quay lại màn Đăng nhập.
      if (code != AuthErrorCode.cancelled) {
        final msg = code.defaultMessage;
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      if (mounted) context.go('/login');
      return;
    }

    final ok = await ref.read(authStateProvider.notifier).completeWebGoogleLogin();
    if (!mounted) return;

    if (ok) {
      // FR-006: thông báo nhẹ khi tài khoản được auto-link (nếu BE gắn cờ).
      final linked = params['linked'];
      if (linked == '1' || linked == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tài khoản Google đã được liên kết với tài khoản Closy hiện có.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      final pending = ref.read(pendingRedirectProvider);
      ref.read(pendingRedirectProvider.notifier).state = null;
      context
          .go((pending != null && pending.isNotEmpty) ? pending : kPostLoginRoute);
      return;
    }

    final err = ref.read(authStateProvider).errorMessage ??
        'Đăng nhập Google thất bại, vui lòng thử lại.';
    setState(() => _error = err);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasError)
                const CircularProgressIndicator(color: AppColors.primary),
              if (hasError)
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Đang hoàn tất đăng nhập Google...',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: hasError ? Colors.red.shade700 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
