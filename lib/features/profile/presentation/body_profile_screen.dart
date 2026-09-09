import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/body_profile_models.dart';
import '../providers/profile_provider.dart';

class BodyProfileScreen extends ConsumerStatefulWidget {
  const BodyProfileScreen({super.key});

  @override
  ConsumerState<BodyProfileScreen> createState() => _BodyProfileScreenState();
}

class _BodyProfileScreenState extends ConsumerState<BodyProfileScreen> {
  late double _height;
  late double _weight;
  late String _selectedBodyShape;
  late TextEditingController _chestController;
  late TextEditingController _waistController;
  late TextEditingController _hipController;
  bool _initialized = false;

  final List<Map<String, dynamic>> _shapes = [
    {
      'id': 'hourglass',
      'title': 'Đồng hồ cát',
      'subtitle': 'Ngực & hông nở, eo thon gọn',
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'id': 'pear',
      'title': 'Dáng quả lê',
      'subtitle': 'Hông và đùi lớn hơn vai',
      'icon': Icons.accessibility_rounded,
    },
    {
      'id': 'rectangle',
      'title': 'Dáng chữ nhật',
      'subtitle': 'Vai, eo và hông tương đương',
      'icon': Icons.crop_portrait_rounded,
    },
    {
      'id': 'inverted_triangle',
      'title': 'Tam giác ngược',
      'subtitle': 'Vai rộng, ngực đầy, hông thon',
      'icon': Icons.change_history_rounded,
    },
    {
      'id': 'apple',
      'title': 'Dáng quả táo',
      'subtitle': 'Vòng eo và thân trên tròn trịa',
      'icon': Icons.radio_button_checked_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _height = 165.0;
    _weight = 52.0;
    _selectedBodyShape = 'hourglass';
    _chestController = TextEditingController();
    _waistController = TextEditingController();
    _hipController = TextEditingController();
  }

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  void _syncFromProfile(BodyProfileModel profile) {
    if (_initialized) return;
    _initialized = true;
    _height = profile.heightCm > 0 ? profile.heightCm : 165.0;
    _weight = profile.weightKg > 0 ? profile.weightKg : 52.0;
    _selectedBodyShape = profile.bodyShape.isNotEmpty ? profile.bodyShape : 'hourglass';
    if (profile.chestCm != null && profile.chestCm! > 0) {
      _chestController.text = profile.chestCm!.toStringAsFixed(1);
    }
    if (profile.waistCm != null && profile.waistCm! > 0) {
      _waistController.text = profile.waistCm!.toStringAsFixed(1);
    }
    if (profile.hipCm != null && profile.hipCm! > 0) {
      _hipController.text = profile.hipCm!.toStringAsFixed(1);
    }
  }

  Future<void> _handleSave() async {
    final chest = double.tryParse(_chestController.text.trim());
    final waist = double.tryParse(_waistController.text.trim());
    final hip = double.tryParse(_hipController.text.trim());

    final updated = BodyProfileModel(
      heightCm: _height,
      weightKg: _weight,
      bodyShape: _selectedBodyShape,
      chestCm: chest,
      waistCm: waist,
      hipCm: hip,
      verifiedByUser: true,
    );

    final success = await ref.read(bodyProfileProvider.notifier).updateProfile(updated);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hồ sơ số đo & dáng người thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(bodyProfileProvider).errorMessage ?? 'Không thể lưu hồ sơ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bodyProfileProvider);
    if (!state.isLoading && !_initialized) {
      _syncFromProfile(state.profile);
    }

    final hInMeters = _height / 100;
    final currentBmi = _weight / (hInMeters * hInMeters);

    String bmiLabel;
    if (currentBmi < 18.5) {
      bmiLabel = 'Mảnh khảnh';
    } else if (currentBmi < 23.0) {
      bmiLabel = 'Cân đối (Chuẩn Châu Á)';
    } else if (currentBmi < 25.0) {
      bmiLabel = 'Đầy đặn';
    } else {
      bmiLabel = 'Thừa cân nhẹ';
    }

    final currentShapeObj = _shapes.firstWhere(
      (s) => s['id'] == _selectedBodyShape,
      orElse: () => _shapes.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hồ sơ Dáng người & Số đo',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: state.isLoading && !_initialized
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Header Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Số đo và dáng người chính xác giúp AI đề xuất outfit chuẩn form và tôn dáng nhất.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Height & Weight Card
                Text(
                  'CHIỀU CAO & CÂN NẶNG',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 0.6),
                  ),
                  child: Column(
                    children: [
                      // Height Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Chiều cao', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(
                            '${_height.toInt()} cm',
                            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Slider(
                        value: _height,
                        min: 130,
                        max: 210,
                        divisions: 80,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        onChanged: (val) => setState(() => _height = val),
                      ),
                      const SizedBox(height: 12),

                      // Weight Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cân nặng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(
                            '${_weight.toInt()} kg',
                            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Slider(
                        value: _weight,
                        min: 35,
                        max: 130,
                        divisions: 95,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        onChanged: (val) => setState(() => _weight = val),
                      ),
                      const SizedBox(height: 8),

                      // BMI status tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 14, color: AppColors.accentSandDark),
                            const SizedBox(width: 8),
                            Text(
                              'BMI: ${currentBmi.toStringAsFixed(1)} • $bmiLabel',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Body Shape Selector
                Text(
                  'DÁNG NGƯỜI (BODY SILHOUETTE)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_shapes.length, (idx) {
                  final shape = _shapes[idx];
                  final isSelected = _selectedBodyShape == shape['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isSelected ? AppColors.accentSand.withOpacity(0.2) : AppColors.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 0.6,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBodyShape = shape['id'] as String;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  shape['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shape['title'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      shape['subtitle'] as String,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Styling Advice Box for Selected Shape
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentSand, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accentSandDark),
                          const SizedBox(width: 8),
                          Text(
                            'GỢI Ý TÔN DÁNG (${currentShapeObj['title']})',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.accentSandDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.profile.copyWith(bodyShape: _selectedBodyShape).bodyShapeStylingAdvice,
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3-Point Measurements (Optional)
                Text(
                  'SỐ ĐO 3 VÒNG (TÙY CHỌN - ĐƠN VỊ CM)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasurementField('Vòng 1 (Ngực)', _chestController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMeasurementField('Vòng 2 (Eo)', _waistController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMeasurementField('Vòng 3 (Hông)', _hipController),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Save Button
                ElevatedButton(
                  onPressed: state.isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu hồ sơ vóc dáng', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildMeasurementField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              hintText: '--',
              suffixText: 'cm',
              suffixStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
