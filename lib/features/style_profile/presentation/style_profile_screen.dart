import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../constants/style_vocabulary.dart';
import '../models/style_profile_models.dart';
import '../providers/style_profile_provider.dart';

class StyleProfileScreen extends ConsumerStatefulWidget {
  const StyleProfileScreen({super.key});

  @override
  ConsumerState<StyleProfileScreen> createState() => _StyleProfileScreenState();
}

class _StyleProfileScreenState extends ConsumerState<StyleProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(styleProfileControllerProvider.notifier).load();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addCustom(bool liked) async {
    final controller = ref.read(styleProfileControllerProvider.notifier);
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          liked ? 'Thêm phong cách bạn mặc' : 'Thêm phong cách bạn tránh',
          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: maxStyleLength,
          decoration: const InputDecoration(hintText: 'Ví dụ: Tối giản Hàn Quốc'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final error = controller.addCustom(liked: liked, value: value);
    if (error != null) _showMessage(error);
  }

  Future<void> _save() async {
    final ok = await ref.read(styleProfileControllerProvider.notifier).save();
    _showMessage(ok ? 'Đã cập nhật gu của bạn' : 'Không lưu được gu của bạn');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xoá hồ sơ gu?'),
        content: const Text('Gu đã lưu sẽ bị xoá. Bạn có thể khai lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(styleProfileControllerProvider.notifier).delete();
    _showMessage(ok ? 'Đã xoá hồ sơ gu' : 'Không xoá được hồ sơ gu');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(styleProfileControllerProvider);
    final controller = ref.read(styleProfileControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Gu của tôi',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!state.locked && state.dirty)
            TextButton(
              onPressed: state.saving ? null : _save,
              child: Text(
                state.saving ? 'ĐANG LƯU' : 'LƯU',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _summary(state),
                  if (state.locked) ...[
                    const SizedBox(height: 20),
                    _paywall(state),
                  ],
                  const SizedBox(height: 20),
                  _section(
                    title: 'TÔI MẶC',
                    liked: true,
                    options: likedStyleOptions,
                    selected: state.styles,
                    maxStyles: state.maxStyles,
                    locked: state.locked,
                    onToggle: (value) {
                      final error = controller.toggle(liked: true, value: value);
                      if (error != null) _showMessage(error);
                    },
                    onAddCustom: () => _addCustom(true),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'TÔI TRÁNH',
                    liked: false,
                    options: avoidedStyleOptions,
                    selected: state.excludedStyles,
                    maxStyles: state.maxStyles,
                    locked: state.locked,
                    onToggle: (value) {
                      final error = controller.toggle(liked: false, value: value);
                      if (error != null) _showMessage(error);
                    },
                    onAddCustom: () => _addCustom(false),
                  ),
                  if (!state.locked) ...[
                    const SizedBox(height: 20),
                    Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 20),
                    _suggestions(state),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: state.deleting ? null : _delete,
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                        label: Text(
                          'Xoá hồ sơ gu',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _summary(StyleProfileState state) {
    final liked = state.styles.take(3).join(' · ');
    final avoided = state.excludedStyles.take(2).join(', ');
    final summary = liked.isEmpty && avoided.isEmpty
        ? 'Chưa chọn phong cách nào'
        : (avoided.isEmpty ? liked : '$liked — tránh $avoided');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HỒ SƠ PHONG CÁCH',
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          summary,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        if (!state.locked) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Áp dụng gu vào gợi ý',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: state.enabled,
                onChanged: state.locked ? null : ref.read(styleProfileControllerProvider.notifier).setEnabled,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 10),
          Text(
            state.error!,
            style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }

  Widget _paywall(StyleProfileState state) {
    final benefits = <String>[
      'Hệ thống nhớ gu giữa các lần phối',
      'Tự học từ những bộ đồ bạn đã lưu',
      'Gợi ý bù món còn thiếu trong tủ',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F1EA), Color(0xFFFBF8F5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.hasExistingProfile ? 'GÓI CỦA BẠN ĐÃ HẾT HẠN' : 'ĐẶC QUYỀN HỘI VIÊN',
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.hasExistingProfile ? 'Gu vẫn được giữ, chỉ chưa được áp dụng' : 'Gu của bạn, được nhớ mỗi lần phối',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('· ', style: TextStyle(color: AppColors.accentSandDark)),
                  Expanded(
                    child: Text(
                      benefit,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () => context.push('/profile/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              child: Text(
                'XEM CÁC GÓI',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required bool liked,
    required List<String> options,
    required List<String> selected,
    required int maxStyles,
    required bool locked,
    required void Function(String value) onToggle,
    required VoidCallback onAddCustom,
  }) {
    final extras = selected
        .where((value) => !options.any((option) => option.toLowerCase() == value.toLowerCase()))
        .toList();
    final all = [...options, ...extras];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${selected.length}/$maxStyles',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in all)
              _chip(
                label: option,
                selected: selected.any((value) => value.toLowerCase() == option.toLowerCase()),
                disabled: locked ||
                    (!selected.any((value) => value.toLowerCase() == option.toLowerCase()) &&
                        selected.length >= maxStyles),
                onTap: () => onToggle(option),
              ),
            if (!locked)
              _chip(label: '+ Thêm', selected: false, disabled: false, onTap: onAddCustom, dashed: true),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required bool disabled,
    required VoidCallback onTap,
    bool dashed = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: selected ? AppColors.accentSand : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: disabled ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: dashed ? AppColors.border : (selected ? AppColors.accentSand : AppColors.border),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 14, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestions(StyleProfileState state) {
    final list = (state.suggestions?.styles ?? const <StyleValueSuggestionModel>[])
        .where((item) => item.itemCount > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TỪ TỦ ĐỒ CỦA BẠN',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (state.suggestions != null)
              Text(
                '${state.suggestions!.sampleSize} món',
                style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.loadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (list.isEmpty)
          Text(
            state.suggestions != null && state.suggestions!.sampleSize == 0
                ? 'Chưa đủ dữ liệu để gợi ý phong cách. Thêm vài món vào tủ đồ rồi quay lại nhé.'
                : 'Chưa có phong cách nào nổi bật trong tủ đồ của bạn.',
            style: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          )
        else
          for (final item in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      item.value,
                      style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.ratio.clamp(0, 1).toDouble(),
                        minHeight: 2,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.accentSand),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(item.ratio * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  IconButton(
                    onPressed: state.styles.any((v) => v.toLowerCase() == item.value.toLowerCase()) ||
                            state.styles.length >= state.maxStyles
                        ? null
                        : () {
                            final error = ref
                                .read(styleProfileControllerProvider.notifier)
                                .toggle(liked: true, value: item.value);
                            if (error != null) _showMessage(error);
                          },
                    icon: const Icon(Icons.add, size: 18),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
