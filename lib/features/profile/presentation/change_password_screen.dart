import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _logoutAllDevices = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final req = ChangePasswordRequest(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
      logoutAllDevices: _logoutAllDevices,
    );

    final success = await ref.read(userProfileProvider.notifier).changePassword(req);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(userProfileProvider).errorMessage ?? 'Đổi mật khẩu thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Đổi mật khẩu',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu cầu mật khẩu an toàn',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mật khẩu mới phải có tối thiểu 8 ký tự, bao gồm ít nhất 1 chữ hoa, 1 chữ thường, 1 số và 1 ký tự đặc biệt.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Old Password
            _buildSectionLabel('MẬT KHẨU HIỆN TẠI *'),
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOld,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
              decoration: _inputDecoration(
                hintText: 'Nhập mật khẩu hiện tại của bạn',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. New Password
            _buildSectionLabel('MẬT KHẨU MỚI *'),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }
                if (val.length < 8) {
                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                }
                final hasUpper = RegExp(r'[A-Z]').hasMatch(val);
                final hasLower = RegExp(r'[a-z]').hasMatch(val);
                final hasDigit = RegExp(r'[0-9]').hasMatch(val);
                final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(val);
                if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                  return 'Mật khẩu phải bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt';
                }
                return null;
              },
              decoration: _inputDecoration(
                hintText: 'Nhập mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Confirm New Password
            _buildSectionLabel('XÁC NHẬN MẬT KHẨU MỚI *'),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập lại mật khẩu mới';
                }
                if (val != _newPasswordController.text) {
                  return 'Mật khẩu xác nhận không trùng khớp';
                }
                return null;
              },
              decoration: _inputDecoration(
                hintText: 'Nhập lại mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Logout all devices switch/checkbox
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                value: _logoutAllDevices,
                activeColor: AppColors.primary,
                title: const Text(
                  'Đăng xuất khỏi tất cả thiết bị khác',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Bảo vệ tài khoản an toàn sau khi đổi mật khẩu',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onChanged: (val) {
                  setState(() {
                    _logoutAllDevices = val ?? true;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),

            // 5. Submit Button
            ElevatedButton(
              onPressed: profileState.isUpdating ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: profileState.isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Xác nhận đổi mật khẩu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }
}
