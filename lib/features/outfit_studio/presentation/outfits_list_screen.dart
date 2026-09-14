import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bulk_deletion_result.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../models/outfit_models.dart';
import '../providers/outfit_studio_provider.dart';
import '../providers/outfits_list_provider.dart';

class OutfitsListScreen extends ConsumerStatefulWidget {
  const OutfitsListScreen({super.key, this.showBackButton = true});

  /// Ẩn nút back khi màn hình nằm trong bottom-nav tab (không có khái niệm back).
  final bool showBackButton;

  @override
  ConsumerState<OutfitsListScreen> createState() => _OutfitsListScreenState();
}

class _OutfitsListScreenState extends ConsumerState<OutfitsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outfitsListProvider.notifier).fetchOutfits();
    });
  }

  void _showOutfitDetailSheet(UserOutfitModel outfit) async {
    final detail = await ref.read(outfitsListProvider.notifier).fetchOutfitDetail(outfit.id);
    final currentOutfit = detail ?? outfit;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cover Image
                  if (currentOutfit.coverImageUrl != null && currentOutfit.coverImageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ClosyNetworkImage(
                          imageUrl: currentOutfit.coverImageUrl!,
                          fit: BoxFit.contain,
                          memCacheWidth: 400,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tên & Ngày tạo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentOutfit.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.6),
                        ),
                        child: Text(
                          currentOutfit.formattedDate,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  if (currentOutfit.description != null && currentOutfit.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentOutfit.description!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Danh sách các món trong Outfit
                  Text(
                    'Các món đồ trong set (${currentOutfit.items.length} món):',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (currentOutfit.items.isEmpty)
                    const Text('Chưa có thông tin chi tiết món đồ.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentOutfit.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = currentOutfit.items[index];
                        final fItem = item.fashionItem;
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 0.6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: fItem != null && fItem.imageUrl.isNotEmpty
                                      ? ClosyNetworkImage(
                                          imageUrl: fItem.imageUrl,
                                          fit: BoxFit.contain,
                                          memCacheWidth: 150,
                                        )
                                      : const Icon(Icons.checkroom, size: 24, color: AppColors.accentSandDark),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fItem?.category?.name ?? 'Món đồ thời trang',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    if (fItem?.style != null && fItem!.style!.isNotEmpty)
                                      Text(
                                        fItem.style!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              if (fItem?.colorHex != null && fItem!.colorHex!.isNotEmpty)
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _parseColorHex(fItem.colorHex!),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black12, width: 0.8),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Nút hành động
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          _confirmDeleteOutfit(currentOutfit);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        label: const Text('Xoá', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInStudioWithConfirm(
                              sheetCtx, currentOutfit),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Mở Trên Studio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Mở outfit đã lưu lên Studio, hỏi ghi đè nếu canvas đang có đồ dở (US 005).
  Future<void> _openInStudioWithConfirm(
      BuildContext sheetCtx, UserOutfitModel outfit) async {
    final hasItems =
        ref.read(outfitStudioProvider).canvasItems.isNotEmpty;
    // Lấy navigator trước async gap (lint use_build_context_synchronously).
    final sheetNavigator = Navigator.of(sheetCtx);
    var replace = true;
    if (hasItems) {
      replace = await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Thay đồ trên canvas?',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w600),
              ),
              content: const Text(
                'Canvas đang có đồ bạn dàn dở. Mở outfit này sẽ thay thế toàn bộ bố cục hiện tại.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Giữ lại',
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Ghi đè'),
                ),
              ],
            ),
          ) ==
          true;
    }
    if (!mounted || !replace) return;
    sheetNavigator.pop();
    ref.read(outfitsListProvider.notifier).loadIntoStudio(outfit);
    if (mounted) context.go('/studio');
  }

  void _confirmDeleteOutfit(UserOutfitModel outfit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận xoá outfit', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: Text('Bạn có chắc chắn muốn xoá bộ trang phục "${outfit.name}" khỏi tủ đồ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref.read(outfitsListProvider.notifier).deleteOutfit(outfit.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xoá outfit thành công.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(outfitsListProvider).errorMessage ?? 'Xoá thất bại'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Xoá ngay'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDeleteOutfits(List<String> ids) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận xoá ${ids.length} outfit',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: Text(
            'Các bộ trang phục đã chọn sẽ bị xoá khỏi tủ đồ và không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Huỷ',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _runBulkDeleteOutfits(ids);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text('Xoá ${ids.length} outfit'),
          ),
        ],
      ),
    );
  }

  Future<void> _runBulkDeleteOutfits(List<String> ids) async {
    final result =
        await ref.read(outfitsListProvider.notifier).deleteOutfits(ids);
    if (!mounted) return;

    if (result.isAllSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xoá ${result.deletedCount} outfit thành công.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      _showBulkDeleteOutfitsFailure(result);
    }
  }

  void _showBulkDeleteOutfitsFailure(BulkDeletionResult result) {
    final outfits = ref.read(outfitsListProvider).outfits;
    final names = result.failedIds
        .map((id) {
          final match = outfits.where((o) => o.id == id);
          // Mục thất bại vẫn còn trong list (giữ lại để thử lại).
          return match.isEmpty ? null : match.first.name;
        })
        .whereType<String>()
        .toList();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xoá chưa hoàn tất'),
        content: Text(
          result.deletedCount > 0
              ? 'Đã xoá ${result.deletedCount} outfit, còn ${result.failedCount} outfit thất bại (${result.describeFailures(names)}). Vui lòng thử lại.'
              : 'Không thể xoá ${result.failedCount} outfit đã chọn. Vui lòng kiểm tra mạng và thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _runBulkDeleteOutfits(result.failedIds);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text('Thử lại (${result.failedCount})'),
          ),
        ],
      ),
    );
  }

  Color _parseColorHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(outfitsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: state.isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.primary),
                tooltip: 'Hủy chọn',
                onPressed: () =>
                    ref.read(outfitsListProvider.notifier).exitSelection(),
              )
            : (widget.showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.primary),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/studio');
                      }
                    },
                  )
                : null),
        title: Text(
          state.isSelecting
              ? '${state.selectedCount} đã chọn'
              : 'Tủ Outfit Của Tôi',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: state.isSelecting
            ? [
                TextButton(
                  onPressed: () =>
                      ref.read(outfitsListProvider.notifier).selectAll(),
                  child: const Text('Chọn tất cả'),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist_rounded,
                      color: AppColors.primary),
                  tooltip: 'Chọn nhiều để xóa',
                  onPressed: () => ref
                      .read(outfitsListProvider.notifier)
                      .enterSelection(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary),
                  onPressed: () =>
                      ref.read(outfitsListProvider.notifier).fetchOutfits(),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary),
                  tooltip: 'Tạo Outfit Mới',
                  onPressed: () => context.go('/studio'),
                ),
                const SizedBox(width: 8),
              ],
      ),
      bottomNavigationBar: state.isSelecting
          ? SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.selectedCount == 0
                            ? 'Chạm để chọn outfit cần xóa'
                            : 'Đã chọn ${state.selectedCount} outfit',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: state.selectedCount == 0
                          ? null
                          : () => _confirmBulkDeleteOutfits(
                              state.selectedIds.toList()),
                      icon:
                          const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('Xóa (${state.selectedCount})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.white.withOpacity(0.25),
                        disabledForegroundColor:
                            Colors.white.withOpacity(0.6),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: NotificationListener<ScrollNotification>(
        // Scroll vô hạn (006, cứng hóa 007): chỉ nghe trục dọc,
        // gần chạm cuối thì tải thêm trang.
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) {
            return false;
          }
          final metrics = notification.metrics;
          if (metrics.maxScrollExtent - metrics.pixels <= 400) {
            ref.read(outfitsListProvider.notifier).loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => ref.read(outfitsListProvider.notifier).fetchOutfits(),
          color: AppColors.primary,
          child: state.isLoading && state.outfits.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : state.errorMessage != null && state.outfits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(state.errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(outfitsListProvider.notifier).fetchOutfits(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : state.outfits.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.checkroom_rounded, size: 40, color: AppColors.accentSandDark),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có bộ trang phục nào',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hãy phối đồ mới bằng AI Stylist hoặc kéo thả tự do trên Studio.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/studio'),
                                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                  label: const Text('Tạo Outfit Ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng cộng ${state.total > 0 ? state.total : state.outfits.length} bộ trang phục',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSand.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tủ đồ số',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.76,
                                ),
                                itemCount: state.outfits.length,
                                itemBuilder: (context, index) {
                                  final outfit = state.outfits[index];
                                  final isSelected = state.selectedIds
                                      .contains(outfit.id);
                                  return _buildOutfitCard(outfit, isSelected);
                                },
                              ),
                            ),
                            // Chỉ báo tải thêm cuối danh sách (US 006)
                            if (state.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
        ),
      ),
    );
  }

  Widget _buildOutfitCard(UserOutfitModel outfit, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (ref.read(outfitsListProvider).isSelecting) {
          ref.read(outfitsListProvider.notifier).toggleSelect(outfit.id);
          return;
        }
        _showOutfitDetailSheet(outfit);
      },
      onLongPress: () {
        final notifier = ref.read(outfitsListProvider.notifier);
        if (!ref.read(outfitsListProvider).isSelecting) {
          notifier.enterSelection(outfit.id);
        } else {
          notifier.toggleSelect(outfit.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F6F0),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: outfit.coverImageUrl != null &&
                              outfit.coverImageUrl!.isNotEmpty
                          ? ClosyNetworkImage(
                              imageUrl: outfit.coverImageUrl!,
                              fit: BoxFit.contain,
                              memCacheWidth: 350,
                            )
                          : const Center(
                              child: Icon(Icons.checkroom_rounded,
                                  size: 40, color: AppColors.accentSandDark),
                            ),
                    ),
                  ),
                  // Selection check badge (US2)
                  if (isSelected)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        outfit.formattedDate,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
