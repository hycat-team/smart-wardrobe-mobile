import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bulk_deletion_result.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../../../shared/widgets/closy_toast.dart';
import '../models/wardrobe_models.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/upload_wardrobe_provider.dart';
import '../utils/analysis_status.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  void _showUploadPicker() {
    // Khoá thao tác trùng khi đang tải (FR-007).
    if (ref.read(uploadWardrobeProvider).isUploading) {
      ClosyToast.info(context, 'Đang tải ảnh, vui lòng đợi hoàn tất...');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm đồ vào tủ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Đã bỏ dòng mô tả "Chụp ảnh hoặc chọn từ máy để AI tự động
              // tách nền và phân tích chất liệu, màu sắc, phong cách." — câu
              // dài chiếm 2 dòng và làm menu rối.
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUpload(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              // Option này chọn nhiều ảnh một lúc nên dùng icon
              // `collections_outlined`; option "Chọn từ thư viện ảnh" (chọn
              // 1 ảnh) đã bị bỏ vì trùng ý và làm menu rối.
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.collections_outlined, color: AppColors.primary),
                ),
                title: const Text('Chọn từ thư viện ảnh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadMultiple(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore_outlined, color: AppColors.primary),
                ),
                title: const Text('Từ tủ đồ hệ thống', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/wardrobe/catalog');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      )
      ),
    );
  }

  void _confirmBulkDelete(List<String> ids) {
    final items = ref.read(wardrobeProvider).items;
    final selected = items.where((it) => ids.contains(it.id)).toList();
    final hasProcessing = selected.any((it) => it.isProcessing);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa ${ids.length} món đồ?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Các món đã chọn sẽ bị xóa khỏi tủ đồ số của bạn và không thể hoàn tác.',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            if (hasProcessing) ...[
              const SizedBox(height: 8),
              const Text(
                'Lưu ý: có món đang được AI phân tích cũng sẽ bị xóa.',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB08968),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _runBulkDelete(ids);
            },
            child: Text('Xóa ${ids.length} món'),
          ),
        ],
      ),
    );
  }

  Future<void> _runBulkDelete(List<String> ids) async {
    final result = await ref.read(wardrobeProvider.notifier).deleteItems(ids);
    if (!mounted) return;

    if (result.isAllSuccess) {
      ClosyToast.success(context, 'Đã xóa ${result.deletedCount} món khỏi tủ đồ.');
    } else {
      _showBulkDeleteFailure(result);
    }
  }

  void _showBulkDeleteFailure(BulkDeletionResult result) {
    final items = ref.read(wardrobeProvider).items;
    final names = result.failedIds
        .map((id) {
          final match = items.where((it) => it.id == id);
          return match.isEmpty ? null : match.first.displayTitle;
        })
        .whereType<String>()
        .toList();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa chưa hoàn tất'),
        content: Text(
          result.deletedCount > 0
              ? 'Đã xóa ${result.deletedCount} món, còn ${result.failedCount} món thất bại (${result.describeFailures(names)}). Vui lòng thử lại.'
              : 'Không thể xóa ${result.failedCount} món đã chọn. Vui lòng kiểm tra mạng và thử lại.',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _runBulkDelete(result.failedIds);
            },
            child: Text('Thử lại (${result.failedCount})'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpload(ImageSource source) async {
    final success = await ref.read(uploadWardrobeProvider.notifier).pickAndUpload(source: source);
    if (!mounted) return;

    if (success) {
      ClosyToast.success(context, 'Đã tải ảnh lên thành công. AI đang phân tích trang phục...');
    } else {
      final error = ref.read(uploadWardrobeProvider).errorMessage;
      if (error != null) {
        ClosyToast.error(context, error);
      }
    }
  }

  Future<void> _handleUploadMultiple(ImageSource source) async {
    final count = await ref
        .read(uploadWardrobeProvider.notifier)
        .pickAndUploadMultiple(source: source);
    if (!mounted) return;

    if (count > 0) {
      ClosyToast.success(context, 'Đã tải $count ảnh lên. AI đang phân tích trang phục...');
    }

    final failed = ref.read(uploadWardrobeProvider).batchFailed;
    if (failed > 0) {
      final msg = ref.read(uploadWardrobeProvider).errorMessage ??
          '$failed ảnh tải lên thất bại. Nhấn "Thử lại" để thử lại.';
      ClosyToast.error(context, msg);
    }
  }

  Widget _buildBatchProgress(UploadWardrobeState s) {
    final total = s.batchTotal;
    final done = s.batchCompleted;
    final failed = s.batchFailed;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.isUploading
                      ? 'Đang tải $done/$total ảnh...'
                      : (failed > 0
                          ? '$failed/$total ảnh tải lên thất bại.'
                          : 'Đã tải $done/$total ảnh.'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (!s.isUploading && failed > 0)
                TextButton(
                  onPressed: () => ref
                      .read(uploadWardrobeProvider.notifier)
                      .retryFailedUploads(),
                  child: const Text('Thử lại'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? null : s.progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for SSE completion notifications
    ref.listen<WardrobeState>(wardrobeProvider, (prev, next) {
      if (next.notificationMessage != null && next.notificationMessage != prev?.notificationMessage) {
        ClosyToast.info(context, next.notificationMessage!);
        ref.read(wardrobeProvider.notifier).clearNotification();
      }
    });

    final wardrobeState = ref.watch(wardrobeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategorySlug = ref.watch(selectedCategorySlugProvider);
    final uploadState = ref.watch(uploadWardrobeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(wardrobeProvider.notifier).loadItems(refresh: true),
            color: AppColors.primary,
            child: NotificationListener<ScrollNotification>(
              // Scroll vô hạn (006, cứng hóa 007): chỉ nghe trục dọc để
              // bỏ qua ListView chips ngang, gần chạm cuối thì tải thêm.
              onNotification: (notification) {
                if (notification.metrics.axis != Axis.vertical) {
                  return false;
                }
                final metrics = notification.metrics;
                if (metrics.maxScrollExtent - metrics.pixels <= 400) {
                  ref.read(wardrobeProvider.notifier).loadMore();
                }
                return false;
              },
              child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: wardrobeState.isSelecting
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
                          tooltip: 'Hủy chọn',
                          onPressed: () =>
                              ref.read(wardrobeProvider.notifier).exitSelection(),
                        )
                      : null,
                  title: Text(
                    wardrobeState.isSelecting
                        ? '${wardrobeState.selectedCount} đã chọn'
                        : 'Tủ đồ số',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  actions: wardrobeState.isSelecting
                      ? [
                          TextButton(
                            onPressed: () => ref
                                .read(wardrobeProvider.notifier)
                                .selectAll(),
                            child: const Text('Chọn tất cả'),
                          ),
                        ]
                      : [
                          IconButton(
                            icon: const Icon(Icons.checklist_rounded,
                                color: AppColors.primary),
                            tooltip: 'Chọn nhiều để xóa',
                            onPressed: () => ref
                                .read(wardrobeProvider.notifier)
                                .enterSelection(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.analytics_outlined,
                                color: AppColors.primary),
                            tooltip: 'Thống kê tủ đồ',
                            onPressed: () => context.push('/wardrobe/insights'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.primary),
                            tooltip: 'Thêm đồ',
                            onPressed:
                                uploadState.isUploading ? null : _showUploadPicker,
                          ),
                        ],
                ),

                if (uploadState.isUploading ||
                    uploadState.failedFiles.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildBatchProgress(uploadState),
                  ),

                // Category Chips Selector
                SliverToBoxAdapter(
                  child: categoriesAsync.when(
                    data: (categories) {
                      return SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: selectedCategorySlug == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref.read(wardrobeProvider.notifier).selectCategory(null);
                                  }
                                },
                                selectedColor: AppColors.primary,
                                // Tick trắng cùng màu chữ khi chọn (US 007).
                                checkmarkColor: selectedCategorySlug == null
                                    ? Colors.white
                                    : AppColors.primary,
                                labelStyle: TextStyle(
                                  color: selectedCategorySlug == null ? Colors.white : AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat.name),
                                  selected: selectedCategorySlug == cat.slug,
                                  onSelected: (selected) {
                                    ref
                                        .read(wardrobeProvider.notifier)
                                        .selectCategory(selected ? cat.slug : null);
                                  },
                                  selectedColor: AppColors.primary,
                                  // Tick trắng cùng màu chữ khi chọn (US 007).
                                  checkmarkColor:
                                      selectedCategorySlug == cat.slug
                                          ? Colors.white
                                          : AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: selectedCategorySlug == cat.slug ? Colors.white : AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    // Không ẩn cả bộ lọc khi API lỗi: hiện thông báo + thử lại.
                    error: (_, __) => SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_outlined,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Không tải được danh mục',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(categoriesProvider),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Item Grid or Empty State
                if (wardrobeState.isLoading && wardrobeState.items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (wardrobeState.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.checkroom_outlined,
                                size: 56,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tủ đồ của bạn đang trống',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hãy chụp ảnh hoặc chọn ảnh quần áo để AI bắt đầu số hóa và phân tích phong cách cho bạn.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showUploadPicker,
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              label: const Text('Thêm trang phục ngay'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = wardrobeState.items[index];
                          final isSelected = wardrobeState.selectedIds.contains(item.id);
                          return WardrobeItemCard(
                            item: item,
                            selected: isSelected,
                            onLongPress: () {
                              final notifier =
                                  ref.read(wardrobeProvider.notifier);
                              if (!wardrobeState.isSelecting) {
                                notifier.enterSelection(item.id);
                              } else {
                                notifier.toggleSelect(item.id);
                              }
                            },
                            onTap: () {
                              if (wardrobeState.isSelecting) {
                                ref
                                    .read(wardrobeProvider.notifier)
                                    .toggleSelect(item.id);
                                return;
                              }
                              if (item.isProcessing) {
                                ClosyToast.info(context, 'Trang phục đang được AI phân tích chi tiết. Vui lòng đợi trong giây lát!');
                                return;
                              }
                              context.push('/wardrobe/item/${item.id}', extra: item);
                            },
                          );
                        },
                        childCount: wardrobeState.items.length,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  ),

                // Chân trang tải thêm (US 006)
                if (wardrobeState.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 32)),
              ],
            ),
          ),
          ),

          // Uploading Banner / Overlay
          if (uploadState.isUploading || uploadState.isAnalyzing)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentSand),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        uploadState.isUploading
                            ? 'Đang tải ảnh lên...'
                            : 'AI đang phân tích trang phục...',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bulk-delete Action Bar (US2)
          if (wardrobeState.isSelecting)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          wardrobeState.selectedCount == 0
                              ? 'Chạm để chọn món cần xóa'
                              : 'Đã chọn ${wardrobeState.selectedCount} món',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: wardrobeState.selectedCount == 0
                            ? null
                            : () => _confirmBulkDelete(
                                wardrobeState.selectedIds.toList()),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text('Xóa (${wardrobeState.selectedCount})'),
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
              ),
            ),
        ],
      ),
    );
  }
}

/// Dedicated Wardrobe Item Card with AutomaticKeepAliveClientMixin.
/// Ensures widget state and decoded image textures are permanently kept in memory
/// during vertical scrolling, completely preventing black screen/blank disposal.
class WardrobeItemCard extends StatefulWidget {
  final WardrobeItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  State<WardrobeItemCard> createState() => _WardrobeItemCardState();
}

class _WardrobeItemCardState extends State<WardrobeItemCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final item = widget.item;
    final imageUrl = item.displayImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.selected
              ? AppColors.primary
              : item.isProcessing
                  ? const Color(0xFFD4A373).withOpacity(0.6)
                  : AppColors.border,
          width: widget.selected ? 2.0 : (item.isProcessing ? 1.2 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: item.isProcessing
                ? const Color(0xFFD4A373).withOpacity(0.12)
                : Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFFF2EFE9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Hero(
                          tag: 'item_${item.id}',
                          // Cho phép Hero flight chạy theo cử chỉ vuốt-back của
                          // hệ thống; mặc định false gây nháy lại khung detail
                          // 1 lần trước khi về list (US1).
                          transitionOnUserGestures: true,
                          child: ClosyNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: 400,
                          ),
                        ),
                      ),
                      // Price badge
                      if (item.price != null && item.price! > 0)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.formattedPrice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      // Status Badges (Processing / NeedsReview / Failed)
                      if (item.isProcessing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8C7A6B).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đang phân tích',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (item.needsReview)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  getAnalysisStatusInfo(item).badgeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (item.isFailed)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C).withOpacity(0.90),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  getAnalysisStatusInfo(item).badgeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Selection check badge (US2)
                      if (widget.selected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayCategoryName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: item.isProcessing
                            ? const Color(0xFFB08968)
                            : (item.needsReview ? const Color(0xFFD97706) : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: item.isProcessing ? AppColors.textSecondary : AppColors.primary,
                        fontStyle: item.isProcessing ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
