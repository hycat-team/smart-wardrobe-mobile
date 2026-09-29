import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/closy_network_image.dart';
import '../../../shared/widgets/closy_toast.dart';
import '../models/wardrobe_models.dart';
import '../providers/wardrobe_provider.dart';
import '../utils/analysis_status.dart';
import 'item_edit_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final WardrobeItemModel? initialItem;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.initialItem,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  WardrobeItemModel? _currentItem;
  String? _selectedReviewCategoryId;
  bool _isActionSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.initialItem;
  }

  Future<void> _submitReviewCategory(WardrobeItemModel item) async {
    if (_selectedReviewCategoryId == null) return;
    setState(() => _isActionSubmitting = true);
    final success = await ref.read(wardrobeProvider.notifier).submitNeedsReview(
          id: item.id,
          categoryId: _selectedReviewCategoryId!,
        );
    if (!mounted) return;
    setState(() => _isActionSubmitting = false);
    if (success) {
      ClosyToast.success(context, 'Đã gửi yêu cầu phân tích lại với danh mục đã chọn.');
      ref.invalidate(wardrobeItemDetailProvider(widget.itemId));
    } else {
      final err = ref.read(wardrobeProvider).errorMessage ?? 'Không thể gửi yêu cầu.';
      ClosyToast.error(context, err);
    }
  }

  Future<void> _retryFailed(WardrobeItemModel item) async {
    setState(() => _isActionSubmitting = true);
    final success = await ref.read(wardrobeProvider.notifier).retryFailedAnalysis(
          id: item.id,
        );
    if (!mounted) return;
    setState(() => _isActionSubmitting = false);
    if (success) {
      ClosyToast.success(context, 'Đang tiến hành phân tích lại...');
      ref.invalidate(wardrobeItemDetailProvider(widget.itemId));
    } else {
      final err = ref.read(wardrobeProvider).errorMessage ?? 'Không thể thử lại.';
      ClosyToast.error(context, err);
    }
  }

  Color _parseColorHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFFD9C5B2);
    try {
      String formatted = hexString.replaceAll('#', '').trim();
      if (formatted.length == 6) {
        formatted = 'FF$formatted';
      }
      return Color(int.parse(formatted, radix: 16));
    } catch (_) {
      return const Color(0xFFD9C5B2);
    }
  }

  void _confirmDelete(WardrobeItemModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa món đồ này?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Món đồ "${item.displayTitle}" sẽ được xóa khỏi tủ đồ số của bạn và giải phóng dung lượng quota.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref.read(wardrobeProvider.notifier).deleteItem(item.id);
              if (!mounted) return;

              if (success) {
                ClosyToast.success(context, 'Đã xóa món đồ khỏi tủ đồ thành công.');
                context.pop();
              } else {
                ClosyToast.error(context, 'Không thể xóa món đồ. Vui lòng thử lại sau.');
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditScreen(WardrobeItemModel item) async {
    final updated = await Navigator.push<WardrobeItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemEditScreen(item: item),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentItem = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(wardrobeItemDetailProvider(widget.itemId));
    // Route đang trong cử chỉ pop (vuốt-back): route không còn current.
    // Giữ nguyên khung hình đã cache, bỏ qua mọi emission mới từ provider
    // giữa chừng cử chỉ để tránh giật/nháy (US1).
    final isPopping = ModalRoute.of(context)?.isCurrent == false;
    if (isPopping && _currentItem != null) {
      return _buildContent(context, _currentItem!);
    }

    return detailAsync.when(
      data: (fetchedItem) {
        // Cache bản mới nhất (không setState): dùng khi pop (xem trên).
        _currentItem = fetchedItem;
        return _buildContent(context, fetchedItem);
      },
      loading: () {
        if (_currentItem != null) {
          return _buildContent(context, _currentItem!);
        }
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
      error: (err, _) {
        if (_currentItem != null) {
          return _buildContent(context, _currentItem!);
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(leading: const BackButton()),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Không thể tải chi tiết món đồ: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(wardrobeItemDetailProvider(widget.itemId)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, WardrobeItemModel item) {
    final fItem = item.fashionItem;
    final colorHex = fItem?.colorHex;
    final parsedColor = _parseColorHex(colorHex);
    final statusInfo = getAnalysisStatusInfo(item);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image with Zoom Support
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(item),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFEDE9E3),
                          Color(0xFFF7F5F0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Hero(
                              tag: 'item_${item.id}',
                              // Đồng bộ với Hero phía list: cho flight chạy
                              // theo cử chỉ vuốt-back, tránh nháy khung (US1).
                              transitionOnUserGestures: true,
                              child: ClosyNetworkImage(
                                imageUrl: item.displayImageUrl,
                                fit: BoxFit.contain,
                                memCacheWidth: 800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Details Body
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Category Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentSand.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (item.category?.name ?? fItem?.category?.name ?? 'Trang phục').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border, width: 0.6),
                            ),
                            child: Text(
                              statusInfo.badgeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.formattedPrice,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        item.displayTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.25,
                        ),
                      ),

                      if (fItem?.brandName != null && fItem!.brandName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Thương hiệu: ${fItem.brandName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      _buildAnalysisStatusSection(context, item, statusInfo),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 24),

                      // Fashion Attributes Grid
                      Text(
                        'THUỘC TÍNH PHÂN TÍCH AI',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.3,
                        children: [
                          _buildAttributeTile(
                            icon: Icons.palette_outlined,
                            label: 'Màu sắc',
                            value: fItem?.color ?? 'Chưa xác định',
                            trailingWidget: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: parsedColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                            ),
                          ),
                          _buildAttributeTile(
                            icon: Icons.checkroom_outlined,
                            label: 'Phong cách',
                            value: fItem?.style ?? 'Casual',
                          ),
                          _buildAttributeTile(
                            icon: Icons.texture_outlined,
                            label: 'Chất liệu',
                            value: fItem?.material ?? 'Cotton / Vải dệt',
                          ),
                          _buildAttributeTile(
                            icon: Icons.grid_view_outlined,
                            label: 'Họa tiết',
                            value: fItem?.pattern ?? 'Trơn',
                          ),
                          _buildAttributeTile(
                            icon: Icons.accessibility_new_outlined,
                            label: 'Kiểu dáng (Fit)',
                            value: fItem?.fit ?? 'Vừa vặn',
                          ),
                          _buildAttributeTile(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Mùa thích hợp',
                            value: fItem?.seasonality ?? 'Bốn mùa',
                          ),
                        ],
                      ),

                      if (fItem?.description != null && fItem!.description!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'MÔ TẢ CHI TIẾT',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fItem.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 100), // Space for sticky bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditScreen(item),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: (item.isProcessing || item.needsReview || item.isFailed)
                            ? null
                            : () {
                                context.push('/studio');
                              },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Phối đồ Studio'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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

  Widget _buildAnalysisStatusSection(
    BuildContext context,
    WardrobeItemModel item,
    AnalysisStatusInfo statusInfo,
  ) {
    if (!item.isProcessing && !item.needsReview && !item.isFailed) {
      return const SizedBox.shrink();
    }

    final isRetrying = ref.watch(wardrobeProvider.notifier).isItemRetrying(item.id) || _isActionSubmitting;

    Color bg;
    Color border;
    Color iconColor;
    IconData iconData;

    if (item.isProcessing) {
      bg = const Color(0xFFF7F5F0);
      border = const Color(0xFFE8E3DC);
      iconColor = AppColors.primary;
      iconData = Icons.auto_awesome;
    } else if (item.needsReview) {
      bg = const Color(0xFFFAF6EB);
      border = const Color(0xFFE5DAC8);
      iconColor = const Color(0xFF9E7B3B);
      iconData = Icons.help_outline_rounded;
    } else if (statusInfo.isInvalidImage) {
      bg = const Color(0xFFFDF2F0);
      border = const Color(0xFFE8C8C4);
      iconColor = const Color(0xFFB04A4A);
      iconData = Icons.warning_amber_rounded;
    } else {
      bg = const Color(0xFFFAF6EB);
      border = const Color(0xFFE5DAC8);
      iconColor = const Color(0xFF9E7B3B);
      iconData = Icons.error_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.isProcessing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                Icon(iconData, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusInfo.badgeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusInfo.detailMessage,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (statusInfo.suggestion != null) ...[
            const SizedBox(height: 6),
            Text(
              statusInfo.suggestion!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (item.needsReview) ...[
            const SizedBox(height: 16),
            const Text(
              'Chọn danh mục trang phục:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ref.watch(categoriesProvider).when(
                  data: (categories) {
                    _selectedReviewCategoryId ??=
                        item.category?.id ?? item.fashionItem?.category?.id;
                    return DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == _selectedReviewCategoryId)
                          ? _selectedReviewCategoryId
                          : null,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text('Chọn một danh mục', style: TextStyle(fontSize: 13)),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedReviewCategoryId = val);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Không thể tải danh sách danh mục.',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isRetrying || _selectedReviewCategoryId == null)
                    ? null
                    : () => _submitReviewCategory(item),
                icon: isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isRetrying ? 'Đang gửi...' : 'Gửi phân tích lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (item.isFailed && statusInfo.canRetry) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRetrying ? null : () => _retryFailed(item),
                icon: isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isRetrying ? 'Đang gửi...' : 'Thử lại phân tích'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributeTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailingWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }
}
