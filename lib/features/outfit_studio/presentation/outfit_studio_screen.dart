import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/outfit_models.dart';
import '../providers/ai_outfit_provider.dart';
import '../providers/outfit_studio_provider.dart';
import '../providers/outfits_list_provider.dart';

class OutfitStudioScreen extends ConsumerStatefulWidget {
  const OutfitStudioScreen({super.key});

  @override
  ConsumerState<OutfitStudioScreen> createState() => _OutfitStudioScreenState();
}

class _OutfitStudioScreenState extends ConsumerState<OutfitStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _outfitNameController = TextEditingController();
  final TextEditingController _drawerSearchController = TextEditingController();
  final TextEditingController _occasionCustomController = TextEditingController();
  final TextEditingController _styleCustomController = TextEditingController();
  final TextEditingController _colorCustomController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  bool _isDrawerSearchOpen = false;

  // 3 options cố định mỗi nhóm (CHK008) + ô tự nhập phía dưới cho giá trị khác.
  final List<Map<String, String>> _occasions = [
    {'label': 'Dạo phố / Cafe', 'value': 'casual'},
    {'label': 'Công sở / Đi làm', 'value': 'work'},
    {'label': 'Hẹn hò', 'value': 'date'},
  ];

  final List<Map<String, String>> _styles = [
    {'label': 'Tối giản (Minimalist)', 'value': 'minimalist'},
    {'label': 'Thanh lịch (Elegant)', 'value': 'elegant'},
    {'label': 'Cổ điển (Vintage)', 'value': 'vintage'},
  ];

  final List<Map<String, String>> _colorTones = [
    {'label': 'Tông sáng', 'value': 'light'},
    {'label': 'Tông trầm / Đen', 'value': 'dark'},
    {'label': 'Pastel dịu ngọt', 'value': 'pastel'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _outfitNameController.dispose();
    _drawerSearchController.dispose();
    _occasionCustomController.dispose();
    _styleCustomController.dispose();
    _colorCustomController.dispose();
    _aiScrollController.dispose();
    super.dispose();
  }

  /// Hỏi ghi đè khi canvas đang có đồ dở trước khi nạp set mới (US 005, FR-009).
  /// Trả về true khi được phép thay thế (canvas trống hoặc user đồng ý).
  Future<bool> _confirmReplaceCanvasIfBusy() async {
    final hasItems = ref.read(outfitStudioProvider).canvasItems.isNotEmpty;
    if (!hasItems) return true;
    final replace = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Thay đồ trên canvas?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        content: const Text(
          'Canvas đang có đồ bạn dàn dở. Nạp set mới sẽ thay thế toàn bộ bố cục hiện tại.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Giữ lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Ghi đè'),
          ),
        ],
      ),
    );
    return replace == true;
  }

  /// Nạp set AI lên canvas sau khi đã xác nhận ghi đè (nếu cần).
  Future<void> _loadAISetWithConfirm(
    RecommendedOutfitRes res, {
    required void Function() afterLoad,
  }) async {
    final confirmed = await _confirmReplaceCanvasIfBusy();
    if (!mounted || !confirmed) return;
    ref.read(outfitStudioProvider.notifier).loadFromAIRecommendation(res);
    afterLoad();
  }

  void _showSaveLookDialog() {
    final studioState = ref.read(outfitStudioProvider);
    if (studioState.canvasItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 món đồ lên Canvas trước khi lưu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _outfitNameController.text = 'Outfit ${DateTime.now().day}/${DateTime.now().month}';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Lưu Bộ Trang Phục',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đặt tên cho set đồ bạn vừa phối:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outfitNameController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Set đồ công sở thứ 2',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _outfitNameController.text.trim();
              Navigator.of(dialogCtx).pop();

              final success = await ref.read(outfitStudioProvider.notifier).saveOutfit(name);
              if (mounted) {
                if (success) {
                  ref.read(outfitsListProvider.notifier).fetchOutfits();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu outfit thành công! Đang chuyển đến tủ đồ...'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  // Về tab Outfits trong shell để giữ bottom navbar,
                  // không dùng route /outfits top-level (mất navbar).
                  context.go('/my-outfits');
                } else {
                  final error = ref.read(outfitStudioProvider).errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Không thể lưu outfit'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu vào Tủ đồ'),
          ),
        ],
      ),
    );
  }

  void _showAlternativePicker(int groupIndex, RecommendedItemGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn món thay thế cho ${group.roleDisplay}',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chạm vào món bạn ưng ý để hoán đổi vào set đồ:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: group.alternatives.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final alt = group.alternatives[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(aiOutfitProvider.notifier).swapAlternative(groupIndex, alt);
                          Navigator.of(bottomSheetCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã đổi sang: ${alt.displayName}'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: alt.imageUrl.isNotEmpty
                                    ? ClosyNetworkImage(
                                        imageUrl: alt.imageUrl,
                                        fit: BoxFit.contain,
                                        memCacheWidth: 250,
                                      )
                                    : const Icon(Icons.checkroom, size: 32, color: AppColors.accentSandDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alt.displayName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiOutfitProvider);
    final studioState = ref.watch(outfitStudioProvider);

    // "Mở Trên Studio" từ list outfit: luôn nhảy sang đúng tab canvas (1),
    // bất kể trước đó đang ở tab AI (0) hay Studio (1). Consume 1 lần.
    if (studioState.openCanvasRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabController.index != 1) {
          _tabController.animateTo(1);
        }
        ref.read(outfitStudioProvider.notifier).consumeCanvasOpenRequest();
      });
    }

    // Tạo set đồ AI xong: tự scroll xuống (animated) để user thấy ngay
    // outfit vừa tạo, không phải kéo tay tìm (CHK009).
    ref.listen<RecommendedOutfitRes?>(
      aiOutfitProvider.select((s) => s.recommendation),
      (prev, next) {
        if (next != null && !identical(prev, next) && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_aiScrollController.hasClients) return;
            _aiScrollController.animateTo(
              _aiScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Outfit Studio',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECE7E1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('AI Gợi Ý Phối Đồ'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.palette_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Studio Thủ Công'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined, color: AppColors.primary),
            tooltip: 'Tủ Outfit của tôi',
            onPressed: () => context.push('/outfits'),
          ),
          if (_tabController.index == 1)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _showSaveLookDialog,
                icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                label: const Text('Lưu Look', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIGeneratorTab(aiState),
          _buildManualStudioTab(studioState),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: AI OUTFIT GENERATOR
  // -------------------------------------------------------------
  /// Ô tự nhập giá trị ngoài 3 options cứng (CHK008). Nhập chữ thì giá trị
  /// tự nhập thắng (chip tắt chọn); bấm chip thì xóa ô tự nhập.
  Widget _buildCustomOptionField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onCustom,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: AppColors.primary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onChanged: (v) {
          final text = v.trim();
          if (text.isNotEmpty) onCustom(text);
        },
      ),
    );
  }

  Widget _buildAIGeneratorTab(AIOutfitState state) {
    return SingleChildScrollView(
      controller: _aiScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Fashion Stylist',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phối set đồ hoàn hảo từ tủ quần áo thật của bạn',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (state.recommendation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Còn ${state.recommendation!.remainingQuota} lượt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Dịp mặc (Occasion)',
            style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _occasions.map((occ) {
              final isSel = state.selectedOccasion == occ['value'];
              return ChoiceChip(
                selected: isSel,
                label: Text(occ['label']!),
                selectedColor: AppColors.accentSand,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.primary,
                ),
                shape: const StadiumBorder(side: BorderSide(color: AppColors.border, width: 0.6)),
                onSelected: (_) {
                  _occasionCustomController.clear();
                  ref.read(aiOutfitProvider.notifier).setOccasion(occ['value']!);
                },
              );
            }).toList(),
          ),
          _buildCustomOptionField(
            controller: _occasionCustomController,
            hintText: 'Hoặc nhập dịp khác... (VD: đi đám cưới, du lịch)',
            onCustom: (v) => ref.read(aiOutfitProvider.notifier).setOccasion(v),
          ),
          const SizedBox(height: 16),

          Text(
            'Phong cách (Style)',
            style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styles.map((st) {
              final isSel = state.selectedStyle == st['value'];
              return ChoiceChip(
                selected: isSel,
                label: Text(st['label']!),
                selectedColor: AppColors.accentSand,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.primary,
                ),
                shape: const StadiumBorder(side: BorderSide(color: AppColors.border, width: 0.6)),
                onSelected: (_) {
                  _styleCustomController.clear();
                  ref.read(aiOutfitProvider.notifier).setStyle(st['value']!);
                },
              );
            }).toList(),
          ),
          _buildCustomOptionField(
            controller: _styleCustomController,
            hintText: 'Hoặc nhập phong cách khác... (VD: Hàn Quốc, công chúa)',
            onCustom: (v) => ref.read(aiOutfitProvider.notifier).setStyle(v),
          ),
          const SizedBox(height: 16),

          Text(
            'Gam màu ưa thích',
            style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorTones.map((tone) {
              final isSel = state.selectedColorTone == tone['value'];
              return ChoiceChip(
                selected: isSel,
                label: Text(tone['label']!),
                selectedColor: AppColors.accentSand,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.primary,
                ),
                shape: const StadiumBorder(side: BorderSide(color: AppColors.border, width: 0.6)),
                onSelected: (_) {
                  _colorCustomController.clear();
                  ref.read(aiOutfitProvider.notifier).setColorTone(tone['value']!);
                },
              );
            }).toList(),
          ),
          _buildCustomOptionField(
            controller: _colorCustomController,
            hintText: 'Hoặc nhập gam màu khác... (VD: trắng kem, xanh navy)',
            onCustom: (v) => ref.read(aiOutfitProvider.notifier).setColorTone(v),
          ),
          const SizedBox(height: 16),

          Text(
            'Yêu cầu đặc biệt cho Stylist (Tuỳ chọn)',
            style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Phối kèm áo khoác cardigan nhẹ hoặc giày sneaker trắng...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () {
                      final promptText = _promptController.text.trim();
                      ref.read(aiOutfitProvider.notifier).setDetails(promptText);
                      ref.read(aiOutfitProvider.notifier).generateOutfit();
                    },
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                state.isLoading ? 'AI đang phối đồ từ tủ đồ...' : 'Tạo Set Đồ Với AI Ngay',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          if (state.recommendation != null) ...[
            const Divider(height: 36),
            _buildRecommendationResult(state.recommendation!),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationResult(RecommendedOutfitRes res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentSand.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.title,
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Stylist Choice • ${res.items.length} món đồ',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, size: 20, color: AppColors.accentSandDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.explanation,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    height: 1.45,
                    color: const Color(0xFF4A443D),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Các món đồ trong set:',
          style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: res.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, groupIndex) {
            final group = res.items[groupIndex];
            final primary = group.primary;
            final hasAlternatives = group.alternatives.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: primary != null && primary.imageUrl.isNotEmpty
                          ? ClosyNetworkImage(
                              imageUrl: primary.imageUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 200,
                            )
                          : const Icon(Icons.checkroom, size: 28, color: AppColors.accentSandDark),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            group.roleDisplay,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          primary?.displayName ?? 'Món đồ thời trang',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (primary?.fashionItem?.style != null)
                          Text(
                            primary!.fashionItem!.style!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  if (hasAlternatives)
                    OutlinedButton.icon(
                      onPressed: () => _showAlternativePicker(groupIndex, group),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                      label: Text(
                        'Đổi (${group.alternatives.length})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _loadAISetWithConfirm(res, afterLoad: () {
                    _tabController.animateTo(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã nạp set đồ vào Studio thủ công để bạn tùy chỉnh toạ độ/layer!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Mở trên Studio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmReplaceCanvasIfBusy();
                  if (!mounted || !confirmed) return;
                  ref.read(outfitStudioProvider.notifier).loadFromAIRecommendation(res);
                  final success = await ref
                      .read(outfitStudioProvider.notifier)
                      .saveOutfit(res.title, description: res.explanation);

                  if (mounted) {
                    if (success) {
                      ref.read(outfitsListProvider.notifier).fetchOutfits();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã lưu outfit vào tủ đồ của bạn! Đang chuyển hướng...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      // Về tab Outfits trong shell để giữ bottom navbar.
                      context.go('/my-outfits');
                    } else {
                      final error = ref.read(outfitStudioProvider).errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Không thể lưu outfit'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bookmark_added_rounded, size: 16),
                label: const Text('Lưu Outfit Ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MANUAL CANVAS STUDIO (RESPONSIVE & STICKY DRAWER)
  // -------------------------------------------------------------
  Widget _buildManualStudioTab(OutfitStudioState state) {
    final filteredItems = state.filteredWardrobeItems;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFAF8F5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: StudioGridPainter(),
                  ),
                ),

                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(outfitStudioProvider.notifier).selectItem(null),
                    child: state.canvasItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.checkroom_outlined, size: 64, color: AppColors.accentSandDark.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'Canvas đang trống',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Kéo khay đồ bên dưới lên để thêm các món từ tủ đồ cá nhân.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Báo kích thước canvas thực tế cho provider để kẹp
                              // vị trí khi nạp set (US 005). Guard ≤1px trong
                              // setCanvasSize nên không gây vòng rebuild.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref
                                    .read(outfitStudioProvider.notifier)
                                    .setCanvasSize(constraints.maxWidth,
                                        constraints.maxHeight);
                              });
                              final canvasWidth = constraints.maxWidth;
                              final canvasHeight = constraints.maxHeight;
                              final centerX = canvasWidth / 2;
                              final centerY = canvasHeight / 2;
                              const baseItemSize = 200.0;

                              return Stack(
                                children: state.canvasItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final isSelected = state.selectedIndex == index;
                                  final itemSize = baseItemSize * item.scale;

                                  return Positioned(
                                    left: centerX + item.positionX - (itemSize / 2),
                                    top: centerY + item.positionY - (itemSize / 2),
                                    child: GestureDetector(
                                      onTap: () => ref.read(outfitStudioProvider.notifier).selectItem(index),
                                      onPanUpdate: (details) {
                                        ref
                                            .read(outfitStudioProvider.notifier)
                                            .updateItemPosition(index, details.delta.dx, details.delta.dy);
                                      },
                                      child: Container(
                                        width: itemSize,
                                        height: itemSize,
                                        decoration: BoxDecoration(
                                          border: isSelected
                                              ? Border.all(color: AppColors.primary, width: 2.0)
                                              : Border.all(color: Colors.transparent, width: 2.0),
                                          borderRadius: BorderRadius.circular(16),
                                          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: ClosyNetworkImage(
                                                imageUrl: item.imageUrl,
                                                fit: BoxFit.contain,
                                                memCacheWidth: 450,
                                              ),
                                            ),
                                            if (isSelected)
                                              Positioned(
                                                bottom: 4,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      item.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                ),

                // Floating Toolbar
                if (state.selectedIndex != null && state.selectedIndex! < state.canvasItems.length)
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.flip_to_front_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Đưa lên trên',
                            onPressed: () =>
                                ref.read(outfitStudioProvider.notifier).bringForward(state.selectedIndex!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_to_back_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Hạ xuống dưới',
                            onPressed: () =>
                                ref.read(outfitStudioProvider.notifier).sendBackward(state.selectedIndex!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_in_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Phóng to',
                            onPressed: () {
                              final curScale = state.canvasItems[state.selectedIndex!].scale;
                              ref
                                  .read(outfitStudioProvider.notifier)
                                  .updateItemScale(state.selectedIndex!, curScale + 0.15);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Thu nhỏ',
                            onPressed: () {
                              final curScale = state.canvasItems[state.selectedIndex!].scale;
                              ref
                                  .read(outfitStudioProvider.notifier)
                                  .updateItemScale(state.selectedIndex!, curScale - 0.15);
                            },
                          ),
                          const Divider(height: 10),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                            tooltip: 'Xoá món',
                            onPressed: () =>
                                ref.read(outfitStudioProvider.notifier).removeItem(state.selectedIndex!),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom Wardrobe Drawer with Sticky Header & Search
        DraggableScrollableSheet(
          initialChildSize: 0.32,
          minChildSize: 0.14,
          maxChildSize: 0.70,
          snap: true,
          snapSizes: const [0.14, 0.32, 0.70],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // STICKY HEADER: Cố định ô tìm kiếm & danh mục khi user scroll
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyDrawerHeaderDelegate(
                      height: 108.0,
                      child: _buildStickyDrawerHeader(state, filteredItems.length),
                    ),
                  ),

                  // Wardrobe Items Grid
                  if (state.isLoadingWardrobe)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSand),
                        ),
                      ),
                    )
                  else if (filteredItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: AppColors.accentSandDark.withOpacity(0.6)),
                              const SizedBox(height: 8),
                              const Text(
                                'Không tìm thấy món đồ phù hợp.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              if (state.selectedDrawerCategory != 'All' || state.drawerSearchQuery.trim().isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _drawerSearchController.clear();
                                    ref.read(outfitStudioProvider.notifier).setDrawerSearchQuery('');
                                    ref.read(outfitStudioProvider.notifier).setDrawerCategory('All');
                                    setState(() => _isDrawerSearchOpen = false);
                                  },
                                  child: const Text('Xem tất cả đồ trong tủ'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredItems[index];
                            final imgUrl = item.displayImageUrl;

                            return GestureDetector(
                              onTap: () {
                                ref.read(outfitStudioProvider.notifier).addItemToCanvas(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã thêm ${item.displayTitle} lên Canvas!'),
                                    duration: const Duration(milliseconds: 900),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 0.6),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: imgUrl.isNotEmpty
                                          ? ClosyNetworkImage(
                                              imageUrl: imgUrl,
                                              fit: BoxFit.contain,
                                              memCacheWidth: 200,
                                            )
                                          : const Icon(Icons.checkroom, size: 24, color: AppColors.accentSandDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.displayTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: filteredItems.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStickyDrawerHeader(OutfitStudioState state, int count) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title Row or Search Field Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: _isDrawerSearchOpen
                ? Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: TextField(
                            controller: _drawerSearchController,
                            autofocus: true,
                            onChanged: (val) {
                              ref.read(outfitStudioProvider.notifier).setDrawerSearchQuery(val);
                            },
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, màu sắc, phong cách...',
                              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                              suffixIcon: _drawerSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () {
                                        _drawerSearchController.clear();
                                        ref.read(outfitStudioProvider.notifier).setDrawerSearchQuery('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        tooltip: 'Đóng tìm kiếm',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          _drawerSearchController.clear();
                          ref.read(outfitStudioProvider.notifier).setDrawerSearchQuery('');
                          setState(() => _isDrawerSearchOpen = false);
                        },
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tủ quần áo cá nhân',
                        style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _isDrawerSearchOpen = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, width: 0.6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tìm đồ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 0.6),
                            ),
                            child: Text(
                              '$count món',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // Category Chips Row
          Container(
            height: 38,
            margin: const EdgeInsets.only(top: 4, bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Áo', 'Quần', 'Váy', 'Giày', 'Phụ kiện'].map((cat) {
                final isSel = state.selectedDrawerCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSel,
                    label: Text(cat),
                    selectedColor: AppColors.accentSand,
                    backgroundColor: AppColors.surfaceSubtle,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.primary,
                    ),
                    shape: const StadiumBorder(side: BorderSide(color: AppColors.border, width: 0.5)),
                    onSelected: (_) => ref.read(outfitStudioProvider.notifier).setDrawerCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Hairline divider
          Container(
            height: 0.6,
            color: AppColors.border.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}

/// Persistent Header Delegate for the Sticky Wardrobe Drawer
class _StickyDrawerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyDrawerHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDrawerHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class StudioGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E3DC)
      ..strokeWidth = 0.5;

    final centerPaint = Paint()
      ..color = const Color(0xFFD8D2C8)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center crosshair lines
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), centerPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
