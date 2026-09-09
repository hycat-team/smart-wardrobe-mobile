import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // OTP State
  bool _isOtpStep = false;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _timeLeft = 59;
  Timer? _timer;
  bool _canResend = false;

  int _selectedGender = 1; // 1: Nam, 2: Nữ, 3: Khác
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 59;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _fillSampleRegister() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    setState(() {
      _firstNameController.text = 'Hoàng';
      _lastNameController.text = 'Nam';
      _usernameController.text = 'user_$timestamp';
      _emailController.text = 'nam_$timestamp@smartwardrobe.com';
      _dobController.text = '1998-05-15';
      _addressController.text = 'Quận 1, TP. Hồ Chí Minh';
      _passwordController.text = 'P@ssword123';
      _confirmPasswordController.text = 'P@ssword123';
      _selectedGender = 1;
    });
  }

  Future<void> _selectDate() async {
    final initialDate = DateTime(1998, 1, 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final request = RegisterRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      address: _addressController.text.trim(),
      gender: _selectedGender,
    );

    final success = await ref.read(authStateProvider.notifier).register(request);
    if (success && mounted) {
      setState(() => _isOtpStep = true);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP đã được gửi đến ${_emailController.text.trim()}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã OTP')),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).confirmRegisterOtp(
          _emailController.text.trim(),
          otp,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kích hoạt tài khoản thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/auth/preferences');
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    await ref.read(authStateProvider.notifier).resendRegisterOtp(_emailController.text.trim());
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
          onPressed: () {
            if (_isOtpStep) {
              setState(() => _isOtpStep = false);
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(
          _isOtpStep ? 'Xác thực OTP' : 'Tạo Tài Khoản',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: _isOtpStep ? _buildOtpView(authState) : _buildRegisterForm(authState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bắt đầu hành trình',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khám phá tủ đồ kỹ thuật số và trợ lý AI phong cách cá nhân.',
            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Demo Quick Fill Chip
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.primary),
              label: const Text('Điền mẫu tự động (Demo)', style: TextStyle(fontSize: 12)),
              backgroundColor: AppColors.accentSand.withOpacity(0.3),
              side: const BorderSide(color: AppColors.accentSand, width: 0.8),
              onPressed: _fillSampleRegister,
            ),
          ),
          const SizedBox(height: 16),

          if (authState.errorMessage != null) _buildErrorBanner(authState.errorMessage!),

          // Họ & Tên
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Họ',
                  hint: 'Nguyễn',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập họ' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'Tên',
                  hint: 'An',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tên đăng nhập
          _buildTextField(
            controller: _usernameController,
            label: 'Tên đăng nhập',
            hint: 'an_nguyen',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (v) => v == null || v.trim().length < 3 ? 'Tối thiểu 3 ký tự' : null,
          ),
          const SizedBox(height: 14),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'an.nguyen@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) => v == null || !v.contains('@') ? 'Email không hợp lệ' : null,
          ),
          const SizedBox(height: 14),

          // Ngày sinh & Giới tính
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _dobController,
                      label: 'Ngày sinh',
                      hint: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_today_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Chọn ngày' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Nam', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 2, child: Text('Nữ', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 3, child: Text('Khác', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGender = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Địa chỉ
          _buildTextField(
            controller: _addressController,
            label: 'Địa chỉ',
            hint: 'Số nhà, Phường, Quận, Thành phố',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập địa chỉ' : null,
          ),
          const SizedBox(height: 14),

          // Mật khẩu
          _buildTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => v == null || v.length < 8 ? 'Tối thiểu 8 ký tự' : null,
          ),
          const SizedBox(height: 14),

          // Xác nhận mật khẩu
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Xác nhận mật khẩu',
            obscureText: _obscureConfirmPassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Nút Đăng ký
          ElevatedButton(
            onPressed: authState.isLoading ? null : _handleRegister,
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
                : const Text('Tiếp tục nhận mã OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),

          // Quay lại Đăng nhập
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Đã có tài khoản? ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpView(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.accentSand.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentSand, width: 1.2),
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Nhập mã xác thực OTP',
          style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Hệ thống đã gửi mã 6 chữ số đến email:\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),

        if (authState.errorMessage != null) _buildErrorBanner(authState.errorMessage!),

        // 6 Ô nhập OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 54,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (index == 5 && val.isNotEmpty) {
                    _handleVerifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),

        // Nút Xác nhận OTP
        ElevatedButton(
          onPressed: authState.isLoading ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: authState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác nhận kích hoạt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),

        // Đếm ngược & Gửi lại
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _canResend ? 'Chưa nhận được mã? ' : 'Gửi lại mã sau: ${_timeLeft}s ',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (_canResend)
                GestureDetector(
                  onTap: _handleResendOtp,
                  child: const Text(
                    'Gửi lại OTP',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      validator: validator,
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8B4B4), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE02424), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF9B1C1C))),
          ),
        ],
      ),
    );
  }
}
