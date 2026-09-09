import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/user_profile_models.dart';
import '../providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDob;
  int _selectedGender = 1; // 1: Nam, 2: Nữ, 3: Khác
  bool _initialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialized) return;
    final user = ref.read(userProfileProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _addressController.text = user.address ?? '';
      if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
        _selectedDob = DateTime.tryParse(user.dateOfBirth!);
      }
      if (user.gender != null) {
        _selectedGender = user.gender!;
      }
      _initialized = true;
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked != null) {
      final success = await ref.read(userProfileProvider.notifier).uploadAvatar(picked);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        final error = ref.read(userProfileProvider).errorMessage ?? 'Lỗi tải ảnh đại diện';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'CHỌN NGÀY SINH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDob = pickedDate;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    String? dobFormatted;
    if (_selectedDob != null) {
      final y = _selectedDob!.year.toString().padLeft(4, '0');
      final m = _selectedDob!.month.toString().padLeft(2, '0');
      final d = _selectedDob!.day.toString().padLeft(2, '0');
      dobFormatted = '$y-$m-$d';
    }

    final req = UpdateProfileRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
      dateOfBirth: dobFormatted,
      gender: _selectedGender,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
    );

    final success = await ref.read(userProfileProvider.notifier).updateProfile(req);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin cá nhân thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(userProfileProvider).errorMessage ?? 'Cập nhật thất bại';
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
    final user = profileState.user;
    _initFields();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa thông tin',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // 1. Avatar with tap to change
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: AppColors.accentSand.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: ClipOval(
                                child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                    ? ClosyNetworkImage(
                                        imageUrl: user.avatarUrl!,
                                        width: 104,
                                        height: 104,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          (user?.fullName ?? user?.username ?? 'U')
                                              .trim()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: profileState.isUpdating ? null : _pickAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: profileState.isUpdating
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: profileState.isUpdating ? null : _pickAvatar,
                          child: const Text(
                            'Thay đổi ảnh đại diện',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Email (Read-only)
                  _buildSectionLabel('EMAIL TÀI KHOẢN'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.verified_user_rounded, size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Name fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('HỌ & TÊN ĐỆM'),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: _inputDecoration(hintText: 'Nguyễn'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('TÊN *'),
                            TextFormField(
                              controller: _firstNameController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Vui lòng nhập tên';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(hintText: 'An'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Gender Selection
                  _buildSectionLabel('GIỚI TÍNH'),
                  Row(
                    children: [
                      _buildGenderOption(1, 'Nam', Icons.male_rounded),
                      const SizedBox(width: 10),
                      _buildGenderOption(2, 'Nữ', Icons.female_rounded),
                      const SizedBox(width: 10),
                      _buildGenderOption(3, 'Khác', Icons.transgender_rounded),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 5. Date of Birth
                  _buildSectionLabel('NGÀY SINH'),
                  GestureDetector(
                    onTap: _selectDateOfBirth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDob != null
                                ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                                : 'Chọn ngày sinh của bạn',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDob != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down_rounded,
                              size: 24, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 6. Address
                  _buildSectionLabel('ĐỊA CHỈ'),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hintText: 'Nhập địa chỉ của bạn (VD: Quận 1, TP. Hồ Chí Minh)',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 7. Save Button
                  ElevatedButton(
                    onPressed: profileState.isUpdating ? null : _handleSave,
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
                            'Lưu thay đổi',
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

  Widget _buildGenderOption(int value, String title, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      prefixIcon: prefixIcon,
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
