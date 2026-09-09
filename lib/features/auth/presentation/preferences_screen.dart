import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  static const List<String> _stylePrefs = [
    'Minimalist',
    'Y2K',
    'Streetwear',
    'Vintage',
    'Workwear',
    'Boho',
    'Casual',
    'Formal',
    'Academia',
    'Gorpcore',
  ];

  static const List<Map<String, dynamic>> _colorPalettes = [
    {
      'name': 'Neutral',
      'subtitle': 'Thanh lịch & Nhã nhặn',
      'colors': [Color(0xFFFAF7F2), Color(0xFF1A1A1A), Color(0xFFB0A9A0)],
    },
    {
      'name': 'Earth',
      'subtitle': 'Tông đất & Thiên nhiên',
      'colors': [Color(0xFF7A8C6E), Color(0xFFC9714A), Color(0xFFF0EBE1)],
    },
    {
      'name': 'Monochrome',
      'subtitle': 'Đen, Trắng & Xám',
      'colors': [Color(0xFF000000), Color(0xFF666666), Color(0xFFCCCCCC)],
    },
    {
      'name': 'Vibrant',
      'subtitle': 'Nổi bật & Đầy năng lượng',
      'colors': [Color(0xFFC9504A), Color(0xFF4A6E8C), Color(0xFFC9A44A)],
    },
  ];

  final Set<String> _selectedStyles = {'Minimalist', 'Casual'};
  String _selectedPalette = 'Neutral';

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        if (_selectedStyles.length > 1) {
          _selectedStyles.remove(style);
        }
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _handleFinish() async {
    await ref.read(authStateProvider.notifier).savePreferences(
          _selectedStyles.toList(),
          _selectedPalette,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ phong cách của bạn đã được thiết lập!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/wardrobe');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
          onPressed: () => context.go('/wardrobe'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/wardrobe'),
            child: const Text(
              'Bỏ qua',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge & Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentSand.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'AI Stylist Profile',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Bước 2/2',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Định Hình Phong Cách',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy cho AI biết gu thẩm mỹ để mang lại những gợi ý phối đồ và tủ đồ kỹ thuật số may đo riêng cho bạn.',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Section 1: Styles
              Row(
                children: [
                  const Text(
                    'Phong cách yêu thích',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_selectedStyles.length} đã chọn)',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _stylePrefs.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return FilterChip(
                    label: Text(style),
                    selected: isSelected,
                    onSelected: (_) => _toggleStyle(style),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.border, width: 0.8),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Section 2: Color Palette
              const Text(
                'Bảng màu chủ đạo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tông màu trang phục bạn thường tự tin nhất khi mặc',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                itemCount: _colorPalettes.length,
                itemBuilder: (context, index) {
                  final palette = _colorPalettes[index];
                  final name = palette['name'] as String;
                  final colors = palette['colors'] as List<Color>;
                  final isSelected = _selectedPalette == name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPalette = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.8 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                          // Palette visual strips
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: colors
                                  .map((c) => Expanded(child: Container(color: c)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),

              // CTA Button
              ElevatedButton(
                onPressed: _handleFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Bắt Đầu Trải Nghiệm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}