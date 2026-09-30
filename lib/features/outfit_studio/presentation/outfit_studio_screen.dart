import 'package:flutter/foundation.dart';
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
import '../../../shared/widgets/closy_toast.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../layout/canvas_layout.dart';
import '../utils/outfit_canvas_exporter.dart';
import '../utils/outfit_name_check.dart';
import 'widgets/floating_save_button.dart';

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

  /// Neo cho vùng kết quả AI (tên + mô tả set). Dùng để auto-scroll dừng
  /// đúng ở đầu vùng này thay vì cuộn tới tận `maxScrollExtent`.
  final GlobalKey _aiResultKey = GlobalKey();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isDrawerExpanded = false;

  /// Tỉ lệ chiều cao hiện tại của khay outfit thay thế (DraggableScrollableSheet).
  /// Chỉ dùng để theo dõi trạng thái gập/mở; vị trí nút lưu đọc trực tiếp
  /// `_sheetController` trong `ListenableBuilder` để bám khay tuyệt đối.
  static const double _kDrawerSnapCollapsed = 0.065;
  static const double _kDrawerSnapExpanded = 0.42;
  static const double _kDrawerSnapMax = 0.70;

  double _gestureItemStartScale = 1.0;
  int? _replacingCanvasIndex;
  final GlobalKey _canvasRepaintKey = GlobalKey();

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
    _sheetController.addListener(_onSheetScrolled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outfitStudioProvider.notifier).loadWardrobe();
      ref.read(wardrobeProvider.notifier).loadItems();
    });
  }

  void _onSheetScrolled() {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;
    final expanded = size > 0.15;
    // Vị trí nút lưu nổi do `ListenableBuilder` đọc trực tiếp
    // `_sheetController` nên không cần setState theo từng frame ở đây.
    if (expanded != _isDrawerExpanded) {
      setState(() {
        _isDrawerExpanded = expanded;
      });
    }
  }

  void _toggleDrawer() {
    if (!_sheetController.isAttached) return;
    if (_isDrawerExpanded) {
      _sheetController.animateTo(
        0.065,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _sheetController.animateTo(
        0.42,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetScrolled);
    _sheetController.dispose();
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Bàn phối đang trống',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: const Text(
            'Vui lòng thêm ít nhất 1 món đồ lên Canvas trước khi lưu.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    // Bỏ chọn món đồ trên canvas để không chụp viền xanh selection box
    ref.read(outfitStudioProvider.notifier).selectItem(null);
    _outfitNameController.text = 'Bộ phối ${DateTime.now().day}/${DateTime.now().month}';

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
            onPressed: () => _saveOutfitWithNameCheck(dialogCtx),
            child: const Text('Lưu vào Tủ đồ'),
          ),
        ],
      ),
    );
  }

  /// Lưu outfit, có chặn tên rỗng và cảnh báo khi trùng tên đã lưu.
  ///
  /// BE (`POST /outfits`) không validate trùng tên nên kiểm tra hoàn toàn
  /// phía client. Đây chỉ là **cảnh báo** — người dùng vẫn có thể lưu.
  Future<void> _saveOutfitWithNameCheck(BuildContext dialogCtx) async {
    final name = _outfitNameController.text.trim();
    if (name.isEmpty) {
      Navigator.of(dialogCtx).pop();
      ClosyToast.error(context, 'Vui lòng đặt tên cho bộ phối trước khi lưu.');
      return;
    }

    final notifier = ref.read(outfitsListProvider.notifier);
    if (ref.read(outfitsListProvider).outfits.isEmpty) {
      await notifier.fetchOutfits();
      if (!mounted) return;
    }

    final duplicate = findDuplicateOutfitByName(
      name,
      ref.read(outfitsListProvider).outfits,
    );

    if (duplicate != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (warnCtx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Bộ phối đã tồn tại',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'Bạn đã có một bộ phối tên "${duplicate.name}" trong tủ. '
            'Vẫn lưu bộ phối này?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(warnCtx).pop(false),
              child: const Text('Đổi tên',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(warnCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Vẫn lưu'),
            ),
          ],
        ),
      );
      if (proceed != true) {
        // Mở lại hộp thoại đặt tên để người dùng sửa tên ngay.
        if (mounted) _showSaveLookDialog();
        return;
      }
    }

    if (!mounted || !dialogCtx.mounted) return;
    Navigator.of(dialogCtx).pop();

    final canvasBytes = await _captureCanvasBytes();
    final success =
        await ref.read(outfitStudioProvider.notifier).saveOutfit(
              name,
              canvasBytes: canvasBytes,
            );
    if (mounted && success) {
      notifier.fetchOutfits();
      context.push('/outfits');
    }
  }

  Future<Uint8List?> _captureCanvasBytes() async {
    final studioState = ref.read(outfitStudioProvider);
    ref.read(outfitStudioProvider.notifier).selectItem(null);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await WidgetsBinding.instance.endOfFrame;

    return await OutfitCanvasExporter.captureFullOutfit(
      boundaryKey: _canvasRepaintKey,
      items: studioState.canvasItems,
      canvasWidth: (studioState.canvasWidth ?? 0) > 0 ? studioState.canvasWidth! : 400.0,
      canvasHeight: (studioState.canvasHeight ?? 0) > 0 ? studioState.canvasHeight! : 500.0,
    );
  }

  void _showAlternativePicker(int groupIndex, RecommendedItemGroup group) {
    final wardrobe = ref.read(outfitStudioProvider).wardrobeItems.isNotEmpty
        ? ref.read(outfitStudioProvider).wardrobeItems
        : ref.read(wardrobeProvider).items;

    final targetRole = normalizeRole(group.role);
    final matchingWardrobe = wardrobe.where((w) {
      if (w.isProcessing) return false;
      if (group.primary != null && w.id == group.primary!.id) return false;
      final role = normalizeRole(
        null,
        categorySlug: w.category?.slug ?? w.fashionItem?.category?.slug,
        categoryName: w.category?.name ?? w.fashionItem?.category?.name,
      );
      if (targetRole == CanvasRole.unknown || targetRole == CanvasRole.other) {
        return true;
      }
      return role == targetRole;
    }).toList();

    final otherWardrobe = wardrobe.where((w) {
      if (w.isProcessing) return false;
      if (group.primary != null && w.id == group.primary!.id) return false;
      return !matchingWardrobe.contains(w);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đổi món cho ${group.roleDisplay}',
                        style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: AppColors.primary),
                        tooltip: 'Quay lại',
                        onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chạm vào món bạn muốn hoán đổi vào set đồ:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  if (group.alternatives.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentSandDark),
                        const SizedBox(width: 6),
                        Text(
                          'Gợi ý tương tự từ AI (${group.alternatives.length})',
                          style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 135,
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
                            },
                            child: Container(
                              width: 105,
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
                                            memCacheWidth: 200,
                                          )
                                        : const Icon(Icons.checkroom, size: 30, color: AppColors.accentSandDark),
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
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      const Icon(Icons.checkroom_rounded, size: 14, color: AppColors.accentSandDark),
                      const SizedBox(width: 6),
                      Text(
                        'Từ tủ đồ của bạn (${matchingWardrobe.length})',
                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (matchingWardrobe.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Text(
                        otherWardrobe.isNotEmpty
                            ? 'Không có món đồ cùng loại (${group.roleDisplay}) trong tủ đồ. Bạn có thể chọn các món khác bên dưới.'
                            : 'Tủ đồ chưa có món nào khác để thay thế.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    SizedBox(
                      height: 135,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: matchingWardrobe.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = matchingWardrobe[index];
                          return GestureDetector(
                            onTap: () {
                              final selectedRes = RecommendedItemRes(
                                id: item.id,
                                itemContext: 'user_wardrobe',
                                fashionItem: RecommendedFashionItemBrief(
                                  id: item.fashionItem?.id ?? item.id,
                                  imageUrl: item.displayImageUrl,
                                  color: item.fashionItem?.color,
                                  category: item.category != null
                                      ? RecommendedCategoryBrief(
                                          id: item.category!.id,
                                          name: item.category!.name,
                                          slug: item.category!.slug,
                                        )
                                      : null,
                                ),
                              );
                              ref.read(aiOutfitProvider.notifier).swapAlternative(groupIndex, selectedRes);
                              Navigator.of(bottomSheetCtx).pop();
                            },
                            child: Container(
                              width: 105,
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
                                    child: item.displayImageUrl.isNotEmpty
                                        ? ClosyNetworkImage(
                                            imageUrl: item.displayImageUrl,
                                            fit: BoxFit.contain,
                                            memCacheWidth: 200,
                                          )
                                        : const Icon(Icons.checkroom, size: 30, color: AppColors.accentSandDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.displayTitle,
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

                  if (matchingWardrobe.isEmpty && otherWardrobe.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tất cả món khác trong tủ (${otherWardrobe.length})',
                      style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 135,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: otherWardrobe.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = otherWardrobe[index];
                          return GestureDetector(
                            onTap: () {
                              final selectedRes = RecommendedItemRes(
                                id: item.id,
                                itemContext: 'user_wardrobe',
                                fashionItem: RecommendedFashionItemBrief(
                                  id: item.fashionItem?.id ?? item.id,
                                  imageUrl: item.displayImageUrl,
                                  color: item.fashionItem?.color,
                                  category: item.category != null
                                      ? RecommendedCategoryBrief(
                                          id: item.category!.id,
                                          name: item.category!.name,
                                          slug: item.category!.slug,
                                        )
                                      : null,
                                ),
                              );
                              ref.read(aiOutfitProvider.notifier).swapAlternative(groupIndex, selectedRes);
                              Navigator.of(bottomSheetCtx).pop();
                            },
                            child: Container(
                              width: 105,
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
                                    child: item.displayImageUrl.isNotEmpty
                                        ? ClosyNetworkImage(
                                            imageUrl: item.displayImageUrl,
                                            fit: BoxFit.contain,
                                            memCacheWidth: 200,
                                          )
                                        : const Icon(Icons.checkroom, size: 30, color: AppColors.accentSandDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.displayTitle,
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
                  ],
                  const SizedBox(height: 10),
                ],
              ),
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
    //
    // Mục tiêu là **đầu vùng kết quả** (tên + mô tả set) chứ không phải
    // `maxScrollExtent` — cuộn tận cuối sẽ nhảy qua mất tên/mô tả và chỉ
    // còn lưới ảnh, mất thông tin quan trọng nhất. `ensureVisible` với
    // `alignment: 0` dừng ở đúng đỉnh vùng kết quả.
    ref.listen<RecommendedOutfitRes?>(
      aiOutfitProvider.select((s) => s.recommendation),
      (prev, next) {
        if (next != null && !identical(prev, next) && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final ctx = _aiResultKey.currentContext;
            if (ctx == null) return;
            Scrollable.ensureVisible(
              ctx,
              alignment: 0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          });
        }
      },
    );

    // Khi AI gặp lỗi (ví dụ: hết lượt tạo trang phục hôm nay):
    // Hiển thị Pop-up Toast ở đỉnh màn hình trong 2 giây rồi tự ẩn (SC-001).
    ref.listen<String?>(
      aiOutfitProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next != null && next.isNotEmpty && next != prev && mounted) {
          ClosyToast.error(context, next);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Phối đồ AI',
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
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildAIGeneratorTab(aiState),
              _buildManualStudioTab(studioState),
            ],
          ),
          if (studioState.isSaving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang hoàn tất và lưu bộ phối...',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đang chụp và tối ưu hình ảnh toàn bộ outfit',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        'Stylist AI',
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
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

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
      key: _aiResultKey,
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

                  OutlinedButton.icon(
                    onPressed: () => _showAlternativePicker(groupIndex, group),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: Text(
                      hasAlternatives ? 'Đổi (${group.alternatives.length})' : 'Đổi món',
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

                  if (mounted && success) {
                    ref.read(outfitsListProvider.notifier).fetchOutfits();
                    context.push('/outfits');
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

    // LayoutBuilder để nút "Lưu Look" nổi neo đúng theo chiều cao thật của
    // vùng vẽ — khớp chính xác mép trên của khay outfit thay thế.
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;

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
                    onTap: () {
                      ref.read(outfitStudioProvider.notifier).selectItem(null);
                      if (_replacingCanvasIndex != null) {
                        setState(() => _replacingCanvasIndex = null);
                      }
                    },
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
                                // Câu hướng dẫn dài: chừa lề 2 bên để không
                                // sát mép màn hình (trước đây tràn ra tận 2 lề).
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Kéo khay đồ bên dưới lên để thêm các món từ tủ đồ cá nhân.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
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

                              // Render theo thứ tự layerOrder (món lớp dưới render trước, lớp trên render sau)
                              final indexedItems = state.canvasItems.asMap().entries.toList()
                                ..sort((a, b) => a.value.layerOrder.compareTo(b.value.layerOrder));

                              return RepaintBoundary(
                                key: _canvasRepaintKey,
                                child: Container(
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  color: const Color(0xFFFAFAFA),
                                  child: Stack(
                                    children: indexedItems.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final isSelected = state.selectedIndex == index;
                                  const double itemScaleMultiplier = 1.25;
                                  final baseS = item.baseScale > 0 ? item.baseScale : 100.0;
                                  final ratioW = item.boxRatioW > 0 ? item.boxRatioW : 2.0;
                                  final ratioH = item.boxRatioH > 0 ? item.boxRatioH : 2.0;
                                  final itemW = baseS * ratioW * item.scale * itemScaleMultiplier;
                                  final itemH = baseS * ratioH * item.scale * itemScaleMultiplier;

                                  return Positioned(
                                    left: centerX + item.positionX - (itemW / 2),
                                    top: centerY + item.positionY - (itemH / 2),
                                    child: GestureDetector(
                                      onTap: () => ref.read(outfitStudioProvider.notifier).selectItem(index),
                                      onScaleStart: (details) {
                                        ref.read(outfitStudioProvider.notifier).selectItem(index);
                                        _gestureItemStartScale = item.scale;
                                      },
                                      onScaleUpdate: (details) {
                                        if (details.pointerCount > 1) {
                                          final newScale = (_gestureItemStartScale * details.scale).clamp(0.15, 3.0);
                                          ref
                                              .read(outfitStudioProvider.notifier)
                                              .updateItemScale(index, newScale);
                                        } else {
                                          ref
                                              .read(outfitStudioProvider.notifier)
                                              .updateItemPosition(index, details.focalPointDelta.dx, details.focalPointDelta.dy);
                                        }
                                      },
                                      child: Container(
                                        width: itemW,
                                        height: itemH,
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
                              ),
                            ),
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
                            tooltip: 'Đưa lên lớp trên',
                            onPressed: () =>
                                ref.read(outfitStudioProvider.notifier).bringForward(state.selectedIndex!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_to_back_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Hạ xuống lớp dưới',
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
                                  .updateItemScale(state.selectedIndex!, (curScale * 1.15).clamp(0.15, 3.0));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Thu nhỏ',
                            onPressed: () {
                              final curScale = state.canvasItems[state.selectedIndex!].scale;
                              ref
                                  .read(outfitStudioProvider.notifier)
                                  .updateItemScale(state.selectedIndex!, (curScale * 0.85).clamp(0.15, 3.0));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'Đổi món này từ tủ đồ',
                            onPressed: () {
                              final selIdx = state.selectedIndex!;
                              final selItem = state.canvasItems[selIdx];
                              final selRole = normalizeRole(selItem.role);
                              String cat = 'All';
                              if (selRole == CanvasRole.top || selRole == CanvasRole.outerwear) {
                                cat = 'Áo';
                              } else if (selRole == CanvasRole.bottom) {
                                cat = 'Quần';
                              } else if (selRole == CanvasRole.fullbody) {
                                cat = 'Váy';
                              } else if (selRole == CanvasRole.footwear) {
                                cat = 'Giày';
                              } else if (selRole == CanvasRole.accessory || selRole == CanvasRole.headwear) {
                                cat = 'Phụ kiện';
                              }
                              ref.read(outfitStudioProvider.notifier).setDrawerCategory(cat);
                              setState(() {
                                _replacingCanvasIndex = selIdx;
                                _isDrawerExpanded = true;
                              });
                              if (_sheetController.isAttached) {
                                _sheetController.animateTo(
                                  0.42,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                );
                              }
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
          controller: _sheetController,
          initialChildSize: _kDrawerSnapCollapsed,
          minChildSize: _kDrawerSnapCollapsed,
          maxChildSize: _kDrawerSnapMax,
          snap: true,
          snapSizes: const [
            _kDrawerSnapCollapsed,
            _kDrawerSnapExpanded,
            _kDrawerSnapMax,
          ],
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
                      height: _isDrawerExpanded ? 108.0 : 48.0,
                      child: _buildStickyDrawerHeader(state),
                    ),
                  ),

                  if (_replacingCanvasIndex != null && _replacingCanvasIndex! < state.canvasItems.length)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentSand, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chọn món thay thế cho "${state.canvasItems[_replacingCanvasIndex!].name}"',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _replacingCanvasIndex = null),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  'Huỷ',
                                  style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                              if (state.selectedDrawerCategory != 'All' ||
                                  state.drawerSearchQuery.trim().isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _drawerSearchController.clear();
                                    ref
                                        .read(outfitStudioProvider.notifier)
                                        .setDrawerSearchQuery('');
                                    ref
                                        .read(outfitStudioProvider.notifier)
                                        .setDrawerCategory('All');
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
                            final isProcessing = item.isProcessing;

                            return GestureDetector(
                              onTap: isProcessing
                                  ? null
                                  : () {
                                      if (_replacingCanvasIndex != null &&
                                          _replacingCanvasIndex! < state.canvasItems.length) {
                                        ref
                                            .read(outfitStudioProvider.notifier)
                                            .replaceItemOnCanvas(_replacingCanvasIndex!, item);
                                        setState(() => _replacingCanvasIndex = null);
                                        ClosyToast.success(context, 'Đã đổi món trên canvas');
                                      } else {
                                        ref.read(outfitStudioProvider.notifier).addItemToCanvas(item);
                                      }
                                    },
                              child: Opacity(
                                opacity: isProcessing ? 0.5 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 0.6),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Stack(
                                    children: [
                                      Column(
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
                                      if (isProcessing)
                                        Positioned(
                                          top: 2,
                                          left: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.65),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Đang phân tích',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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

        // Nút "Lưu" dính liền và di chuyển CÙNG khay outfit thay thế: đọc
        // trực tiếp `_sheetController.size` trong cùng frame với khay nên
        // lệch 0px (không "đuổi" như `AnimatedPositioned` trước đây).
        // `Align` chỉ hit-test đúng vùng nút nên không chặn kéo/thả trên canvas.
        if (state.canvasItems.isNotEmpty)
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _sheetController,
              builder: (context, _) {
                final lift =
                    _sheetController.size * viewportHeight + kSaveButtonGap;
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: FloatingSaveLookButton(
                        isSaving: state.isSaving,
                        hasItems: state.canvasItems.isNotEmpty,
                        onPressed: _showSaveLookDialog,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
      },
    );
  }

  Widget _buildStickyDrawerHeader(OutfitStudioState state) {
    if (!_isDrawerExpanded) {
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: _toggleDrawer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checkroom_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Tủ quần áo cá nhân',
                          style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar (tap to collapse)
          GestureDetector(
            onTap: _toggleDrawer,
            behavior: HitTestBehavior.opaque,
            child: Center(
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
          ),

          // Header giống hệt trạng thái đóng: cùng tiêu đề, cùng padding,
          // chỉ mũi tên quay xuống. Kéo drawer lên không làm layout nhảy.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checkroom_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Tủ quần áo cá nhân',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.primary,
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
                    label: Text(cat == 'All' ? 'Tất cả' : cat),
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
