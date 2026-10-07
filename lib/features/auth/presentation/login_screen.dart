import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/closy_toast.dart';
import 'widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).clearMessages();
    });
  }

  @override
  void dispose() {
    _loginNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
          _loginNameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (success && authState.isAuthenticated) {
      final user = authState.user;
      final greeting = user?.fullName ?? _loginNameController.text.trim();
      ClosyToast.success(context, 'Đăng nhập thành công! Chào mừng $greeting.');
      // Quay lại đích đến đã giữ trước khi bị đá về /login (ví dụ trang
      // thông báo kết quả thanh toán từ deep-link/cold-start).
      final pending = ref.read(pendingRedirectProvider);
      ref.read(pendingRedirectProvider.notifier).state = null;
      context.go((pending != null && pending.isNotEmpty) ? pending : kPostLoginRoute);
    } else {
      final error = authState.errorMessage ?? 'Sai tài khoản hoặc mật khẩu.';
      ClosyToast.error(context, error);
    }
  }

  void _handleGoogleOutcome(GoogleSignInOutcome outcome) {
    if (!mounted) return;

    if (outcome.success) {
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      final greeting = user?.fullName ?? _loginNameController.text.trim();

      if (outcome.linkedExistingAccount) {
        ClosyToast.info(
          context,
          outcome.message ??
              'Tài khoản Google đã được liên kết với tài khoản Closy của bạn.',
          duration: const Duration(seconds: 4),
        );
      } else {
        ClosyToast.success(context, 'Đăng nhập thành công! Chào mừng $greeting.');
      }

      final pending = ref.read(pendingRedirectProvider);
      ref.read(pendingRedirectProvider.notifier).state = null;
      context.go((pending != null && pending.isNotEmpty) ? pending : kPostLoginRoute);
    } else {
      if (outcome.errorCode == AuthErrorCode.cancelled) {
        return;
      }
      final error = outcome.message ?? 'Đăng nhập Google thất bại.';
      ClosyToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Spec 015 — FR-007/FR-008/FR-009 (US2): khi đang lấy phiên đăng nhập, PHỦ
    // TOÀN MÀN HÌNH bằng một lớp chặn tương tác, thay vì chỉ xoay spinner trên
    // nút. Lớp phủ nuốt mọi chạm/nhấn — kể cả nhấn lại nút "Đăng nhập", nên bấm
    // liên tục chỉ sinh MỘT yêu cầu.
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Image.asset(
                        'assets/images/logo-full.png',
                        width: 168,
                        height: 168,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                          semanticLabel: 'Logo Closy',
                        errorBuilder: (context, error, stackTrace) => Text(
                          'CLOSY',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chào mừng trở lại',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (authState.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8B4B4), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFE02424), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      controller: _loginNameController,
                      keyboardType: TextInputType.emailAddress,
                      // Enter ở ô tài khoản → chuyển sang ô mật khẩu.
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: 'Email hoặc Tên đăng nhập',
                        // Không dùng hintText: nhãn đã nói rõ nhập gì, thêm
                        // hint "user hoặc user@smartwardrobe.com" chỉ nhắc lại
                        // và tốn một dòng trong ô.
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Vui lòng nhập email hoặc username' : null,
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      // Enter ở ô mật khẩu → đăng nhập luôn.
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (authState.isLoading) return;
                        _handleLogin();
                      },
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                    ),
                    const SizedBox(height: 8),

                    // Quên mật khẩu
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/auth/forgot-password'),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Đăng nhập
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),

                    // Divider HOẶC (Quiet Luxury)
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border, thickness: 0.8)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'HOẶC',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.border, thickness: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút Đăng nhập bằng Google
                    GoogleSignInButton(
                      onOutcome: _handleGoogleOutcome,
                    ),
                    const SizedBox(height: 24),

                    // Chưa có tài khoản? Đăng ký
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/auth/register'),
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
        if (authState.isLoading)
          // FR-009: nhãn tiếng Việt nói rõ đang xử lý. Vùng chạm >= 44px.
          Positioned.fill(
            child: AbsorbPointer(
              // FR-008: nuốt mọi chạm/nhấn, kể cả nhấn lại nút Đăng nhập.
              absorbing: true,
              child: Container(
                color: AppColors.background.withOpacity(0.92),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentSandDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Đang xử lý, vui lòng chờ...',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
